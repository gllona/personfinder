# Person Finder — Local Setup on Ubuntu 24.x

This guide covers cloning, running, and configuring Person Finder on a Linux box
with Docker and Docker Compose already installed.

**References:**
- [Person Finder help site](https://support.google.com/personfinder/)
- [Live demo (Google)](https://google.org/personfinder/demo/)

---

## 1. Clone the repository

```bash
git clone https://github.com/<your-fork>/personfinder.git
cd personfinder
```

---

## 2. Start the application

```bash
docker compose up --build -d
```

On first run, Docker builds the image (several minutes). Subsequent starts are
fast. The app is available at `http://localhost:7777`.

**Ports:**

| URL | Purpose |
|---|---|
| `http://localhost:7777` | Application (user-facing) |
| `http://localhost:7779` | GAE admin panel |

---

## 3. Initialize the datastore (first time only)

Visit `http://localhost:7777/setup_datastore` in your browser. This creates the
required Datastore schema. It is a one-time operation — subsequent restarts reuse
the existing data.

### Datastore persistence

Data is stored in `./data/datastore.db` on the host, bind-mounted into the
container. It survives `docker compose down` and reboots. The `data/` directory
is gitignored so it is never committed.

---

## 4. Log in as administrator

Admin pages require a Google account marked as administrator. In the local dev
server, a fake login page appears automatically:

1. Enter email address `test@example.com`.
2. **Check "Sign in as Administrator".**
3. Submit.

---

## 5. Global settings

Visit `http://localhost:7777/global/admin` to configure site-wide settings such
as the site title, reCAPTCHA keys, and Maps API key.

---

## 6. Create a new event repo

Each disaster or event is an independent **repo** with its own URL, title, and
configuration.

1. Go to `http://localhost:7777/global/admin/create_repo`.
2. Enter a short, lowercase repo ID (e.g. `sad-event`).
3. Submit — the repo is created in **Staging** mode (not yet public).

The repo is now accessible at `http://localhost:7777/personfinder/sad-event`.

---

## 7. Configure the repo

Go to `http://localhost:7777/sad-event/admin` and update these key fields:

| Setting | Description |
|---|---|
| **Repo title** | Display name per language, e.g. `{"en": "Sad Event 2026", "es-419": "Evento Triste 2026"}` |
| **Language menu options** | Languages shown in the UI, e.g. `es-419, en` — list primary language first |
| **Map default center** | `[lat, lon]` of the affected area |
| **Map default zoom** | `6`–`7` for country/region view |
| **Time zone offset** | UTC offset in hours (e.g. `-4` for Venezuela) |
| **Keywords** | Comma-separated search keywords for SEO |
| **Activation status** | Change from **Staging** → **Active** when ready to go live |
| **Launched** | Check to make the repo appear on the global home page |

Save the form. The repo is now live at `http://localhost:7777/personfinder/sad-event`.

### Translations

Translation `.mo` files are compiled automatically at container startup (from the
`.po` source files under `app/locale/`). All 80+ languages ship with the
repository. To add `Spanish (Latin America)` as the primary language, set
`language_menu_options` to `es-419, en`.

---

## 8. Useful local URLs

| URL | Purpose |
|---|---|
| `http://localhost:7777/personfinder/demo` | Browse all active repos |
| `http://localhost:7777/personfinder/sad-event` | Your custom repo (public view) |
| `http://localhost:7777/sad-event/admin` | Your custom repo admin |
| `http://localhost:7777/global/admin` | Global settings |
| `http://localhost:7779/` | GAE admin panel (queues, cron, datastore viewer) |

---

## 9. Run as a systemd service

To start Person Finder automatically on boot:

```bash
sudo cp docker/personfinder.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable personfinder
sudo systemctl start personfinder
```

Check status:

```bash
sudo systemctl status personfinder
```

View logs:

```bash
journalctl -u personfinder -f
```

> **NordVPN users:** The NordVPN killswitch blocks host→container traffic on all
> Docker bridges. If containers are unreachable from the host, run:
> ```bash
> nordvpn set lan-discovery enable
> nordvpn allowlist add subnet 172.16.0.0/12
> ```

---

## 10. Stopping and updating

```bash
# Stop
docker compose down

# Pull latest code and rebuild
git pull
docker compose up --build -d
```

The datastore is preserved across rebuilds — no need to re-run `setup_datastore`.
