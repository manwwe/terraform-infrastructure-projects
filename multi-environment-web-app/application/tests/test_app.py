from datetime import datetime, timezone

import pytest

from snake_app import create_app


class FakeRepository:
    def __init__(self):
        self.healthy = True
        self.fail = False
        self.scores = [
            {
                "id": 1,
                "score": 80,
                "created_at": datetime(2026, 9, 3, tzinfo=timezone.utc).isoformat(),
            }
        ]

    def is_healthy(self):
        if self.fail:
            raise RuntimeError("database unavailable")
        return self.healthy

    def list_scores(self, limit=10):
        if self.fail:
            raise RuntimeError("database unavailable")
        return self.scores[:limit]

    def create_score(self, score):
        if self.fail:
            raise RuntimeError("database unavailable")
        created = {
            "id": len(self.scores) + 1,
            "score": score,
            "created_at": datetime(2026, 9, 3, 12, 0, tzinfo=timezone.utc).isoformat(),
        }
        self.scores.append(created)
        return created


@pytest.fixture
def repository():
    return FakeRepository()


@pytest.fixture
def client(repository):
    app = create_app(repository)
    app.config.update(TESTING=True)
    return app.test_client()


def test_health_reports_database_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json() == {"status": "healthy"}


def test_health_reports_database_failure(client, repository):
    repository.fail = True
    response = client.get("/health")
    assert response.status_code == 503
    assert response.get_json() == {"status": "unhealthy"}


def test_lists_top_scores(client):
    response = client.get("/api/scores")
    assert response.status_code == 200
    assert response.get_json()["scores"][0]["score"] == 80


def test_creates_score(client):
    response = client.post("/api/scores", json={"score": 120})
    assert response.status_code == 201
    assert response.get_json()["score"] == 120


@pytest.mark.parametrize(
    "payload",
    [
        None,
        {},
        {"score": True},
        {"score": "120"},
        {"score": -1},
        {"score": 1_000_001},
        {"score": 10, "extra": "value"},
    ],
)
def test_rejects_invalid_scores(client, payload):
    response = client.post("/api/scores", json=payload)
    assert response.status_code == 400


def test_database_errors_do_not_leak_details(client, repository):
    repository.fail = True
    response = client.get("/api/scores")
    assert response.status_code == 503
    assert response.get_json() == {"error": "database_unavailable"}
