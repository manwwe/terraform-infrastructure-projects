# Flask Snake Application Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the temporary Nginx page with a playable Snake game whose anonymous scores are validated by Flask and persisted in the private PostgreSQL database.

**Architecture:** Keep application source outside Terraform and inject the files into EC2 user data as gzip-compressed, base64-encoded, non-secret artifacts that remain below EC2's 16 KiB limit. Flask serves the game and a small REST API behind Gunicorn and Nginx; the process retrieves the RDS-managed username and password from Secrets Manager through the EC2 instance role.

**Tech Stack:** Python 3, Flask, Gunicorn, psycopg 3, boto3, PostgreSQL, vanilla JavaScript, HTML canvas, CSS, pytest, systemd, Nginx

---

## File Map

- Create `application/snake_app/__init__.py`: Flask application factory and HTTP routes.
- Create `application/snake_app/database.py`: environment configuration, secret retrieval, PostgreSQL repository, and schema initialization.
- Create `application/snake_app/init_db.py`: retrying database initialization command.
- Create `application/snake_app/wsgi.py`: Gunicorn entry point.
- Create `application/snake_app/templates/index.html`: accessible game structure.
- Create `application/snake_app/static/styles.css`: arcade visual system and responsive layout.
- Create `application/snake_app/static/game.js`: Snake engine, controls, API calls, and UI states.
- Create `application/tests/test_app.py`: API contract tests with an in-memory repository fake.
- Create `application/tests/test_database.py`: secret parsing and initialization retry tests.
- Create `application/requirements.txt` and `application/requirements-dev.txt`: pinned runtime and test dependencies.
- Modify `environments/dev/templates/compute_user_data.sh.tftpl`: install and run the application without secret values.
- Modify `environments/dev/main.tf`: pass non-secret database settings and encoded application files to the bootstrap template.

### Task 1: Build the Tested Flask API

- [x] Write failing Flask client tests for `GET /health`, `GET /api/scores`, and `POST /api/scores`.
- [x] Require `POST /api/scores` to accept JSON shaped exactly as `{"score": 120}`, return `201`, and reject booleans, strings, missing values, negative values, and values above `1_000_000` with `400`.
- [x] Implement an application factory that accepts a repository dependency so tests never contact AWS or PostgreSQL.
- [x] Return only `id`, `score`, and ISO-8601 `created_at` fields from the score API.
- [x] Convert repository failures into a generic `503` JSON response and log the exception without exposing credentials.
- [x] Run `pytest application/tests/test_app.py -q`; expect all tests to pass.

### Task 2: Implement Secure Database Access

- [x] Read `AWS_REGION`, `DB_SECRET_ARN`, `DB_HOST`, `DB_PORT`, and `DB_NAME` from process environment.
- [x] Retrieve `SecretString` with `secretsmanager:GetSecretValue`, require string `username` and `password` fields, and cache the parsed credential only in process memory.
- [x] Open short-lived psycopg connections with TLS required and bounded connection timeouts.
- [x] Create a `snake_scores` table with an identity key, bounded integer score, and UTC creation timestamp.
- [x] Add five-attempt database initialization with five seconds between attempts; raise after the final failure so systemd can restart the service.
- [x] Run `pytest application/tests/test_database.py -q`; expect all tests to pass.

### Task 3: Build the Snake Interface

- [x] Create a responsive HTML canvas game with keyboard and on-screen directional controls.
- [x] Use a near-black cabinet, phosphor-green snake, amber food, and quiet border-only depth.
- [x] Display the current score, game state, and top-ten database scores.
- [x] Prevent immediate direction reversal, grow on food, detect wall/self collisions, and increase speed gradually.
- [x] Submit the final score once per completed game and refresh the leaderboard.
- [x] Implement loading, empty, success, and failure states without blocking gameplay.

### Task 4: Bootstrap the Application on EC2

- [x] Compress and encode application source files with Terraform `base64gzip(file(...))`, enforce the 16 KiB user-data limit in the compute module, and pass only non-secret RDS metadata directly to `templatefile`.
- [x] Decode source under `/opt/snake-app`, create a virtual environment, and install pinned dependencies.
- [x] Run Gunicorn as an unprivileged `snake` system user on `127.0.0.1:8000`.
- [x] Configure Nginx to proxy port 80 to Gunicorn and keep `/health` available for the future target group.
- [x] Store only region, secret ARN, endpoint, port, and database name in a root-readable environment file; never interpolate a password into Terraform or user data.
- [x] Run Terraform formatting, module tests, and development-root validation. Do not run `terraform apply`.

### Task 5: Final Verification

- [x] Run `python -m pytest application/tests -q` and expect all application tests to pass.
- [x] Run `terraform -chdir=modules/compute test` and expect all compute tests to pass.
- [x] Run `terraform -chdir=environments/dev validate` and expect success.
- [x] Review the rendered user-data inputs and confirm that no real username or password exists in source, Terraform configuration, or test fixtures.
- [x] Commit the application and bootstrap as one reviewable feature commit.
