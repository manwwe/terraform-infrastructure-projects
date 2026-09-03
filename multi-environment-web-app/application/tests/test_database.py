import json
from datetime import datetime, timezone

import pytest

from snake_app import database
from snake_app.database import (
    DatabaseConfig,
    ScoreRepository,
    build_connection_factory,
    load_credentials,
    parse_secret,
)
from snake_app.init_db import initialize_with_retry


def test_reads_database_config_from_environment(monkeypatch):
    values = {
        "AWS_REGION": "us-east-1",
        "DB_SECRET_ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:test",
        "DB_HOST": "database.internal",
        "DB_PORT": "5432",
        "DB_NAME": "appdb",
    }
    for name, value in values.items():
        monkeypatch.setenv(name, value)

    config = DatabaseConfig.from_environment()

    assert config.host == "database.internal"
    assert config.port == 5432
    assert config.database_name == "appdb"


def test_database_config_rejects_invalid_port(monkeypatch):
    monkeypatch.setenv("AWS_REGION", "us-east-1")
    monkeypatch.setenv("DB_SECRET_ARN", "secret-arn")
    monkeypatch.setenv("DB_HOST", "database.internal")
    monkeypatch.setenv("DB_PORT", "70000")
    monkeypatch.setenv("DB_NAME", "appdb")

    with pytest.raises(RuntimeError, match="between 1 and 65535"):
        DatabaseConfig.from_environment()


def test_parse_secret_returns_credentials():
    assert parse_secret(json.dumps({"username": "app", "password": "private"})) == (
        "app",
        "private",
    )


@pytest.mark.parametrize(
    "secret",
    [
        "not-json",
        "null",
        "[]",
        "{}",
        '{"username": "app"}',
        '{"username": "", "password": "private"}',
    ],
)
def test_parse_secret_rejects_invalid_values(secret):
    with pytest.raises(RuntimeError):
        parse_secret(secret)


def test_load_credentials_calls_secrets_manager_once(monkeypatch):
    calls = []

    class FakeSecretsClient:
        def get_secret_value(self, **kwargs):
            calls.append(kwargs)
            return {"SecretString": '{"username":"app","password":"private"}'}

    monkeypatch.setattr(
        database.boto3,
        "client",
        lambda service, region_name: FakeSecretsClient(),
    )
    load_credentials.cache_clear()

    first = load_credentials("us-east-1", "secret-arn")
    second = load_credentials("us-east-1", "secret-arn")

    assert first == second == ("app", "private")
    assert calls == [{"SecretId": "secret-arn"}]
    load_credentials.cache_clear()


def test_connection_factory_requires_tls_and_timeout(monkeypatch):
    captured = {}
    connection = object()
    config = DatabaseConfig(
        aws_region="us-east-1",
        secret_arn="secret-arn",
        host="database.internal",
        port=5432,
        database_name="appdb",
    )

    def fake_connect(**kwargs):
        captured.update(kwargs)
        return connection

    monkeypatch.setattr(database.psycopg, "connect", fake_connect)
    factory = build_connection_factory(
        config,
        credential_loader=lambda region, arn: ("app", "private"),
    )

    assert factory() is connection
    assert captured == {
        "host": "database.internal",
        "port": 5432,
        "dbname": "appdb",
        "user": "app",
        "password": "private",
        "sslmode": "require",
        "connect_timeout": 5,
    }


class FakeCursor:
    def __init__(self, rows=None):
        self.rows = list(rows or [])
        self.executions = []

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def execute(self, query, parameters=None):
        self.executions.append((query, parameters))

    def fetchone(self):
        return self.rows[0] if self.rows else None

    def fetchall(self):
        return self.rows


class FakeConnection:
    def __init__(self, cursor):
        self._cursor = cursor
        self.exited = False

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.exited = True
        return False

    def cursor(self):
        return self._cursor


def test_repository_initializes_bounded_score_schema():
    cursor = FakeCursor()
    connection = FakeConnection(cursor)

    ScoreRepository(lambda: connection).initialize()

    query, parameters = cursor.executions[0]
    assert "CREATE TABLE IF NOT EXISTS snake_scores" in query
    assert "CHECK (score BETWEEN 0 AND 1000000)" in query
    assert parameters is None
    assert connection.exited is True


def test_repository_lists_top_ten_scores_in_rank_order():
    created_at = datetime(2026, 9, 3, tzinfo=timezone.utc)
    cursor = FakeCursor([(7, 300, created_at)])

    scores = ScoreRepository(lambda: FakeConnection(cursor)).list_scores()

    query, parameters = cursor.executions[0]
    assert "ORDER BY score DESC, created_at ASC" in query
    assert parameters == (10,)
    assert scores == [{"id": 7, "score": 300, "created_at": created_at.isoformat()}]


def test_repository_inserts_and_serializes_score():
    created_at = datetime(2026, 9, 3, tzinfo=timezone.utc)
    cursor = FakeCursor([(8, 420, created_at)])

    created = ScoreRepository(lambda: FakeConnection(cursor)).create_score(420)

    query, parameters = cursor.executions[0]
    assert "INSERT INTO snake_scores" in query
    assert parameters == (420,)
    assert created == {"id": 8, "score": 420, "created_at": created_at.isoformat()}


def test_initialize_retries_then_succeeds():
    calls = []
    sleeps = []

    def initialize():
        calls.append(True)
        if len(calls) < 3:
            raise RuntimeError("not ready")

    initialize_with_retry(initialize, attempts=5, delay_seconds=5, sleep=sleeps.append)

    assert len(calls) == 3
    assert sleeps == [5, 5]


def test_initialize_raises_final_error():
    def initialize():
        raise RuntimeError("still unavailable")

    with pytest.raises(RuntimeError, match="still unavailable"):
        initialize_with_retry(initialize, attempts=2, delay_seconds=0, sleep=lambda _: None)
