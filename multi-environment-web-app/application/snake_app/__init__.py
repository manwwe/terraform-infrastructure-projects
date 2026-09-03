import logging
from typing import Any, Optional, Protocol

from flask import Flask, jsonify, render_template, request

from .database import create_repository


class Repository(Protocol):
    def is_healthy(self) -> bool: ...

    def list_scores(self, limit: int = 10) -> list[dict[str, Any]]: ...

    def create_score(self, score: int) -> dict[str, Any]: ...


def create_app(repository: Optional[Repository] = None) -> Flask:
    app = Flask(__name__)
    score_repository = repository or create_repository()

    @app.get("/")
    def index() -> str:
        return render_template("index.html")

    @app.get("/health")
    def health():
        try:
            if not score_repository.is_healthy():
                raise RuntimeError("Database health query returned an unexpected result")
        except Exception:
            app.logger.exception("Application health check failed")
            return jsonify(status="unhealthy"), 503
        return jsonify(status="healthy")

    @app.get("/api/scores")
    def list_scores():
        try:
            scores = score_repository.list_scores(limit=10)
        except Exception:
            app.logger.exception("Unable to load scores")
            return jsonify(error="database_unavailable"), 503
        return jsonify(scores=scores)

    @app.post("/api/scores")
    def create_score():
        payload = request.get_json(silent=True)
        if not isinstance(payload, dict) or set(payload) != {"score"}:
            return jsonify(error="score_is_required"), 400

        score = payload["score"]
        if type(score) is not int or not 0 <= score <= 1_000_000:
            return jsonify(error="score_must_be_an_integer_between_0_and_1000000"), 400

        try:
            created_score = score_repository.create_score(score)
        except Exception:
            app.logger.exception("Unable to save score")
            return jsonify(error="database_unavailable"), 503
        return jsonify(created_score), 201

    logging.getLogger("werkzeug").setLevel(logging.WARNING)
    return app
