import json
import os
from dataclasses import dataclass
from datetime import datetime
from functools import lru_cache
from typing import Any, Callable

import boto3
import psycopg


@dataclass(frozen=True)
class DatabaseConfig:
    aws_region: str
    secret_arn: str
    host: str
    port: int
    database_name: str

    @classmethod
    def from_environment(cls) -> "DatabaseConfig":
        required = {
            "AWS_REGION": os.environ.get("AWS_REGION"),
            "DB_SECRET_ARN": os.environ.get("DB_SECRET_ARN"),
            "DB_HOST": os.environ.get("DB_HOST"),
            "DB_PORT": os.environ.get("DB_PORT"),
            "DB_NAME": os.environ.get("DB_NAME"),
        }
        missing = [name for name, value in required.items() if not value]
        if missing:
            raise RuntimeError(
                f"Missing required environment variables: {', '.join(sorted(missing))}"
            )

        try:
            port = int(required["DB_PORT"])
        except (TypeError, ValueError) as error:
            raise RuntimeError("DB_PORT must be an integer") from error

        if not 1 <= port <= 65535:
            raise RuntimeError("DB_PORT must be between 1 and 65535")

        return cls(
            aws_region=str(required["AWS_REGION"]),
            secret_arn=str(required["DB_SECRET_ARN"]),
            host=str(required["DB_HOST"]),
            port=port,
            database_name=str(required["DB_NAME"]),
        )


def parse_secret(secret_string: str) -> tuple[str, str]:
    try:
        secret = json.loads(secret_string)
    except json.JSONDecodeError as error:
        raise RuntimeError("The database secret is not valid JSON") from error

    if not isinstance(secret, dict):
        raise RuntimeError("The database secret must be a JSON object")

    username = secret.get("username")
    password = secret.get("password")
    if not isinstance(username, str) or not username:
        raise RuntimeError("The database secret does not contain a valid username")
    if not isinstance(password, str) or not password:
        raise RuntimeError("The database secret does not contain a valid password")
    return username, password


@lru_cache(maxsize=1)
def load_credentials(region: str, secret_arn: str) -> tuple[str, str]:
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_arn)
    secret_string = response.get("SecretString")
    if not isinstance(secret_string, str):
        raise RuntimeError("The database secret must use SecretString")
    return parse_secret(secret_string)


def build_connection_factory(
    config: DatabaseConfig,
    credential_loader: Callable[[str, str], tuple[str, str]] = load_credentials,
) -> Callable[[], psycopg.Connection[Any]]:
    def connect() -> psycopg.Connection[Any]:
        username, password = credential_loader(config.aws_region, config.secret_arn)
        return psycopg.connect(
            host=config.host,
            port=config.port,
            dbname=config.database_name,
            user=username,
            password=password,
            sslmode="require",
            connect_timeout=5,
        )

    return connect


class ScoreRepository:
    def __init__(self, connection_factory: Callable[[], psycopg.Connection[Any]]):
        self._connection_factory = connection_factory

    def initialize(self) -> None:
        with self._connection_factory() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    CREATE TABLE IF NOT EXISTS snake_scores (
                        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                        score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 1000000),
                        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )

    def is_healthy(self) -> bool:
        with self._connection_factory() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                return cursor.fetchone() == (1,)

    def list_scores(self, limit: int = 10) -> list[dict[str, Any]]:
        with self._connection_factory() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT id, score, created_at
                    FROM snake_scores
                    ORDER BY score DESC, created_at ASC
                    LIMIT %s
                    """,
                    (limit,),
                )
                return [self._serialize(row) for row in cursor.fetchall()]

    def create_score(self, score: int) -> dict[str, Any]:
        with self._connection_factory() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO snake_scores (score)
                    VALUES (%s)
                    RETURNING id, score, created_at
                    """,
                    (score,),
                )
                row = cursor.fetchone()
                if row is None:
                    raise RuntimeError("PostgreSQL did not return the created score")
                return self._serialize(row)

    @staticmethod
    def _serialize(row: tuple[int, int, datetime]) -> dict[str, Any]:
        identifier, score, created_at = row
        return {
            "id": identifier,
            "score": score,
            "created_at": created_at.isoformat(),
        }


def create_repository() -> ScoreRepository:
    config = DatabaseConfig.from_environment()
    return ScoreRepository(build_connection_factory(config))
