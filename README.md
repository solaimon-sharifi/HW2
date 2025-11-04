# Run the automated SQL steps and collect outputs

After starting the stack with `docker compose up --build -d`, you can run the helper script which executes the A–E SQL steps (CREATE, INSERT, SELECT, JOIN, UPDATE, DELETE) inside the `db` container and saves textual outputs into the `reports/` directory.

1. Make the script executable and run it:

```bash
chmod +x ./scripts/run_sql_steps.sh
./scripts/run_sql_steps.sh
```

2. The script writes files to `reports/` (for example `reports/step_C_select_users.txt`) which you can open and include as text or screenshots in your Word/PDF submission.

Notes about screenshots/PDF

- For grading you still need screenshots from pgAdmin showing the Query Tool UI and the result grids; the `reports/` files provide a textual backup and are handy for pasting results into a document.
- Use the README's screenshot checklist to capture images and compile them into your Word or PDF submission.

API examples (curl) and outputs

I added a script that runs a few example API calls (using curl) and saves the HTTP response headers and body to `reports/`.

Run it like this (after the containers are up):

```bash
chmod +x ./scripts/run_api_examples.sh
./scripts/run_api_examples.sh
```

Files produced include:
- `reports/api_1_health.txt` — health endpoint response
- `reports/api_2_list_users_before.txt` — users before creating `carol`
- `reports/api_3_create_user_carol.txt` — response from creating `carol`
- `reports/api_4_list_users_after.txt` — users after creating `carol`
- `reports/api_5_list_calculations_before.txt` — calculations before creating new one
- `reports/api_6_create_calculation.txt` — response from creating a calculation for `carol`
- `reports/api_7_list_calculations_after.txt` — calculations after insertion
- `reports/api_8_calculations_join.txt` — joined view (users + calculations)

- `reports/api_9_update_calc_1.txt` — response from PATCH /calculations/1
- `reports/api_9_select_calc_1.txt` — calculations list after update
- `reports/api_10_delete_calc_2.txt` — response from DELETE /calculations/2
- `reports/api_10_select_after_delete.txt` — calculations list after delete
- `reports/api_11_update_user_3.txt` — response from PATCH /users/3
- `reports/api_11_select_user_list.txt` — users list after update
- `reports/api_12_delete_user_3.txt` — response from DELETE /users/3
- `reports/api_12_select_user_list_after_delete.txt` — users list after delete

These files can be pasted into your Word/PDF submission along with pgAdmin screenshots.

Generate a submission document (markdown + optional PDF)

The repository includes a template and a generator that collects the outputs from `reports/` and produces `submission/submission.md`. If `pandoc` is installed, it will also generate `submission/submission.pdf`.

The submission template includes image placeholders that will be embedded in the PDF if you place your screenshots in the `screenshots/` directory with the filenames below.

Expected screenshot filenames (place your pgAdmin screenshots here):

- `screenshots/pgadmin_login.png` — pgAdmin login page
- `screenshots/pgadmin_server.png` — configured server entry in pgAdmin
- `screenshots/step_A_create.png` — CREATE TABLES Query Tool screenshot
- `screenshots/step_B_insert.png` — INSERT queries screenshot
- `screenshots/step_C_select_users.png` — SELECT * FROM users result grid
- `screenshots/step_C_select_calculations.png` — SELECT * FROM calculations result grid
- `screenshots/step_C_join.png` — JOIN query result
- `screenshots/step_D_update.png` — UPDATE query screenshot
- `screenshots/step_E_delete.png` — DELETE query screenshot

Run the generator:

```bash
chmod +x ./scripts/generate_submission.sh
./scripts/generate_submission.sh
```

If `pandoc` is installed the script will also attempt to produce `submission/submission.pdf`. The generated markdown references the images in `../screenshots/...` relative to `submission/submission.md`, so ensure the `screenshots/` directory is at the repo root.

# FastAPI + PostgreSQL + pgAdmin (Docker Compose)

This project provides a fully working development environment using FastAPI, PostgreSQL and pgAdmin via Docker Compose. The API connects to Postgres via SQLAlchemy. pgAdmin runs on port 5050 and allows you to run SQL queries against the database.

Folder structure

```
.
├── api/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── db.py
│   │   ├── models.py
│   │   └── schemas.py
│   ├── requirements.txt
│   └── Dockerfile
├── db/
│   └── init.sql
├── .env
├── .gitignore
├── docker-compose.yml
└── README.md
```

Quick run instructions

1. Make sure Docker and Docker Compose are installed on your machine.
2. From the project root, copy `.env` or edit values inside it if you want different credentials.
3. Start the system:

```bash
docker compose up --build -d
```

4. Check containers:

```bash
docker compose ps
```

5. FastAPI docs: http://localhost:8000/docs

6. pgAdmin: http://localhost:5050

   - Login with the credentials from `.env` (PGADMIN_DEFAULT_EMAIL / PGADMIN_DEFAULT_PASSWORD).
   - Add a new server in pgAdmin:
     - Name: fastapi-db (or any name)
     - Connection -> Host name/address: db
     - Port: 5432
     - Maintenance DB: fastapi_db
     - Username: fastapi_user
     - Password: fastapi_pass

Note: inside Docker Compose network the Postgres hostname is `db`. If you connect from your host machine (outside Docker) to Postgres directly use `localhost` and port `5432`.


Database initialization

When Postgres first starts it runs `db/init.sql` which creates `users` and `calculations` tables and inserts seeded rows for the assignment.

Follow these SQL steps in pgAdmin Query Tool (A-E)

A) CREATE TABLES
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE calculations (
    id SERIAL PRIMARY KEY,
    operation VARCHAR(20) NOT NULL,
    operand_a FLOAT NOT NULL,
    operand_b FLOAT NOT NULL,
    result FLOAT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

B) INSERT RECORDS
```sql
INSERT INTO users (username, email) 
VALUES 
('alice', 'alice@example.com'), 
('bob', 'bob@example.com');

INSERT INTO calculations (operation, operand_a, operand_b, result, user_id)
VALUES
('add', 2, 3, 5, 1),
('divide', 10, 2, 5, 1),
('multiply', 4, 5, 20, 2);
```

C) QUERY DATA
```sql
-- Retrieve all users
SELECT * FROM users;

-- Retrieve all calculations
SELECT * FROM calculations;

-- Join users and calculations
SELECT u.username, c.operation, c.operand_a, c.operand_b, c.result
FROM calculations c
JOIN users u ON c.user_id = u.id;
```

D) UPDATE A RECORD
```sql
UPDATE calculations
SET result = 6
WHERE id = 1;  -- or whichever row you want to update
```

E) DELETE A RECORD
```sql
DELETE FROM calculations
WHERE id = 2;  -- example record to remove
```

## Security & secrets

A few important steps and tools to keep your repository and CI secure.

- If you accidentally exposed an API key (for example an OpenAI `sk-` key), revoke it immediately from the provider's dashboard. For OpenAI go to:
    https://platform.openai.com/account/api-keys

- Add real credentials to GitHub Actions as repository Secrets instead of committing them into files.
    1. Go to your repository → Settings → Secrets and variables → Actions → New repository secret.
    2. Add values such as `POSTGRES_PASSWORD`, `OPENAI_API_KEY`, etc.
    3. The CI workflow will prefer these secrets when present.

- Quick local secret-scan with gitleaks (recommended before pushing):

```bash
# Install (macOS/Homebrew / Linux packages / binary download)
# Then run from the repo root:
gitleaks detect --source . --redact
```

- If you must remove a secret from git history (dangerous — rewrites history):

Option A — `git-filter-repo` (recommended):

```bash
# Make a mirror backup first
git clone --mirror git@github.com:youruser/yourrepo.git /tmp/repo-mirror.git
cd /tmp/repo-mirror.git
# Create a file mapping literal secret -> replacement
echo 'sk-REPLACE_THIS==>REMOVED-OPENAI-KEY' > replace.txt
# Run filter-repo to replace the secret across history
git filter-repo --replace-text replace.txt
# Force-push cleaned history
git push --force --all origin
git push --force --tags origin
```

Option B — BFG Repo-Cleaner (simpler UI):

```bash
# Mirror-clone then run BFG with a file that contains the literal secret
git clone --mirror git@github.com:youruser/yourrepo.git
java -jar bfg.jar --replace-text passwords.txt repo.git
cd repo.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force
```

- After scrubbing: inform collaborators to re-clone the repo (history was rewritten).

If you'd like, I can run the scrub locally and prepare the cleaned repo and/or add a small docs page describing exactly which secrets to rotate and where to update CI. Reply with which of the following you want me to do next:

- `revoke-guidance` — I will give exact revocation steps per provider you name (OpenAI, AWS, GitHub PAT, etc.).
- `clean-local` — I will remove the literal secret from this repo's history locally and leave a cleaned repo for you to inspect (no force-push).
- `clean-and-push <remote>` — I will clean and force-push to the given remote (must confirm you accept history rewrite).


Documenting outputs and screenshots

1. After each SQL command run in pgAdmin, take a screenshot showing the Query Tool: the SQL you ran and the output (e.g., "Query returned successfully: X rows affected" or the result grid).
2. Compile the screenshots in a Word document or PDF. For each screenshot add a one-line caption describing what it shows (e.g., "CREATE TABLE users: Query returned successfully").
3. Include a screenshot of `docker compose ps` output showing the three services up.
4. Add a short reflection (1-2 paragraphs) describing any issues you encountered and what you learned.


Screenshot checklist for grading

1. pgAdmin login page visible (http://localhost:5050) with the admin email in the browser address bar.
2. A configured server entry in pgAdmin that connects to the `db` Postgres container.
3. pgAdmin Query Tool showing results of a SELECT (e.g., `SELECT * FROM users;`).
4. Docker Compose showing all three services up (api, db, pgadmin) — `docker compose ps` output.
5. FastAPI docs page loaded at http://localhost:8000/docs showing the endpoints.
6. Example query in pgAdmin demonstrating a JOIN between `users` and `items`.

Troubleshooting

- If pgAdmin cannot reach the Postgres server when adding a new server, ensure you're using the host `db` (the Docker service name) and port `5432`. If you try to connect from the host machine (outside Docker) use `localhost:5432` and ensure the port is exposed (it is in docker-compose.yml).
- If tables are missing, ensure the Postgres container ran init scripts on first startup — you may need to remove the `db_data` volume to re-run initialization:

```bash
docker compose down
docker volume rm hw2_db_data || true
docker compose up --build
```

But note: removing the volume deletes all database data.

Files to inspect

- `db/init.sql` — initial schema and seed data
- `api/app/models.py` — SQLAlchemy models
- `api/app/db.py` — SQLAlchemy engine and session
- `api/app/main.py` — FastAPI app and endpoints

Commands to stop and remove containers

```bash
docker compose down
```

Running the automated tests (pytest)

You can run the end-to-end API tests locally after starting the stack. The test suite uses the public API endpoints (HTTP) and requires the services to be up (FastAPI on port 8000).

1. Install dev requirements:

```bash
python -m pip install --user -r dev-requirements.txt
```

2. Start services:

```bash
make up
```

3. Run tests:

```bash
pytest -q tests
```

The CI workflow also runs the same tests and will fail the run if any assertion fails.

That's it — you should now have a working stack with FastAPI, PostgreSQL and pgAdmin.
