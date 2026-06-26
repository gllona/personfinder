# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Person Finder is a searchable missing person database running on Google App Engine (Python 2.7, with ongoing Python 3 migration). It implements the PFIF data model and provides import/export of PFIF feeds. Hosted at https://google.org/personfinder/.

## Commands

### Running Tests

```bash
tools/all_tests                          # Run all tests (lint + unit + server + UI)
tools/unit_tests                         # Python 2.7 unit tests
tools/unit_tests test_model test_indexing  # Run specific test modules
tools/py3_unit_tests                     # Python 3 unit tests
tools/server_tests                       # End-to-end server tests (starts a dev server)
tools/server_tests -k ConfigTests        # Run server tests matching a pattern
tools/server_tests -k test_delete        # Run a specific test method
```

### Linting

```bash
tools/lint flake8-check   # Flake8 (max 80 chars); covers app/views, app/tasksmodule, tests/views, tests/tasks
tools/lint pylint-check   # Pylint (stricter); covers a subset of files
```

### Running the Dev Server

The dev server requires the App Engine SDK and is typically run via Docker:
```bash
docker-compose up
```
This starts the dev_appserver on port 8000.

### React UI

```bash
tools/ui run         # Start webpack dev server (talks to backend at port 8080)
tools/ui test        # Run React tests
tools/ui buildtoae   # Compile and copy bundles to app/resources/static/fixed/ui_bundles/
```

To develop the React UI locally:
1. Run the Django backend server on port 8080
2. Enable the React UI: `./tools/console localhost:8080` → `config.set(enable_react_ui=True)`
3. Run `tools/ui run`

### Update Translations

```bash
tools/update_messages    # Update message files for i18n
```

## Architecture

### Backend (`app/`)

The backend is a Python 2.7 Google App Engine app using Django 1.11 as a web framework and GAE Datastore (via the old `google.appengine.ext.db` ORM) for storage.

**Key files:**
- `app/wsgi.py` — WSGI entrypoint
- `app/urls.py` — URL routing (all routes defined here)
- `app/model.py` — Core data models (`Person`, `Note`, `Repo`) using GAE `db`
- `app/config.py` — Runtime configuration stored in Datastore; access via `config.get()`/`config.set()`
- `app/site_settings.py` — Install-time settings (e.g., `OPTIONAL_PATH_PREFIX = 'personfinder'`)
- `app/settings.py` — Django settings

**View hierarchy:**
- `app/views/base.py` — `BaseView` (extends `django.views.View`); all new views inherit from this
- `app/views/admin/base.py` — `AdminBaseView` for admin pages (checks Google account/ACLs)
- `app/tasksmodule/base.py` — `TasksBaseView` for App Engine task queue handlers (requires `X-AppEngine-TaskName` header)
- `app/views/frontendapi.py` — JSON API endpoints at `/<repo>/d/` consumed by the React UI

**Old vs. new code:** Legacy handler code lives as flat `app/*.py` files (e.g., `create.py`, `results.py`). New code is structured into `app/views/` (class-based Django views) and `app/tasksmodule/`.

**Resources/Templates:**
- `app/resources/` — Django templates and static files
- Files with `.template` suffix are Django templates
- Files with `:<lang>` suffix (e.g., `base.html.template:ja`) are localized versions
- `app/resources/static/fixed/` — Served directly as static files at `/static/`

**Search:**
- `app/search/searcher.py` — `Searcher` class; routes to either prefix-based search (`indexing.py`) or full-text search (`full_text_search.py`) based on repo config

### React Frontend (`ui/`)

A React/Webpack app that provides a non-AMP UI. Source is in `ui/src/`; compiled bundles go to `app/resources/static/fixed/ui_bundles/` (one JS bundle per language, one CSS bundle). Uses `react-intl` for translations; message IDs follow `ComponentName.messageName` convention.

### Tests (`tests/`)

- `tests/views/` — Django view tests (class-based, use `django.test.Client`)
- `tests/tasks/` — Task handler tests
- `tests/testutils/base.py` — `ServerTestsBase`: activates GAE testbed stubs (in-memory Datastore, memcache) for isolated tests
- `tests/testutils/data_generator.py` — `TestDataGenerator` for creating test fixtures
- `tests/*.py` — Legacy flat unit tests run via `tests/unit_tests.py`

### URL Structure

All URL patterns support an optional `/personfinder/` prefix (via `OPTIONAL_PATH_PREFIX`):
- `/<repo>/admin/` — Admin views
- `/<repo>/d/` — Frontend API (JSON, for React UI)
- `/<repo>/tasks/` — Task queue handlers
- `/global/` — Global/cross-repo views
- `/setup_datastore/` — One-time setup

### Code Style

- Python: [Google Python Style Guide](https://github.com/google/styleguide/blob/gh-pages/pyguide.md)
- JavaScript: [Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)
- Max line length: 80 characters
