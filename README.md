# Grooveprint

A local "Shazam for vinyl" — identifies records playing on a turntable by matching microphone audio against a personal music catalog.

## How It Works

1. **Ingest** your vinyl collection — audio files are fingerprinted and stored in a local database
2. **Listen** — the Android client captures audio from the turntable and sends it to the server
3. **Match** — the server identifies the record in real-time
4. **Display** — the web UI shows the currently playing track with cover art and metadata

## Server

### Requirements

- Python 3.12+
- ffmpeg
- libsndfile

### Quick Start

```bash
cd server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
./run_local.sh
```

The server starts on port **8457**. Open `http://localhost:8457` for the web UI.

### Docker

```bash
cd server
docker-compose up --build
```

Mounts `./data` as a persistent volume for the database and cover art.

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GROOVEPRINT_DB_PATH` | `./data/fingerprints.db` | Path to the SQLite database |
| `GIT_COMMIT` | `dev` | Version string shown in `/health` |

### Web UI

Served at `/` with four views:

- **Now Playing** — real-time display of the currently identified record
- **Library** — browse and manage your album/track catalog
- **Upload** — drag-and-drop ingestion of audio files or ZIP archives
- **Settings** — configure integrations (Roon Now Playing)

### API

| Method | Path | Description |
|---|---|---|
| `POST` | `/listen` | Send WAV audio for continuous matching (202, async) |
| `POST` | `/match` | One-shot match, returns results |
| `GET` | `/now-playing` | Current playback state |
| `GET` | `/now-playing/stream` | SSE stream of now-playing updates |
| `POST` | `/ingest` | Ingest a single audio file |
| `POST` | `/ingest/bulk` | Ingest multiple files or ZIP archives |
| `GET/POST/PUT/DELETE` | `/albums`, `/albums/{id}` | Album CRUD |
| `GET/PUT/DELETE` | `/tracks`, `/tracks/{id}` | Track CRUD |
| `POST` | `/albums/{id}/cover` | Upload cover art |
| `GET/PUT` | `/settings` | Server settings |
| `GET` | `/health` | Database stats and version |

### Roon Now Playing

The server can push now-playing updates to a [Roon Now Playing](https://github.com/arthursoares/roon-now-playing) display. Configure via the web UI Settings page or `PUT /settings`:

```json
{
  "roon_enabled": true,
  "roon_url": "http://10.0.1.9:8377",
  "roon_zone_name": "Record Player",
  "server_url": "http://10.0.1.9:8457"
}
```

### Tests

```bash
cd server && source venv/bin/activate
pytest tests/
```

## Ingestion

```bash
cd scripts
python ingest.py /path/to/album --server http://localhost:8457
```

Options: `--recursive` (`-r`), `--dry-run`, `--discogs URL`

ZIP archives uploaded via the web UI can include a `.txt` or `.md` file with a Discogs release URL — side and position info is populated automatically.

## Android Client

Kotlin/Compose app for Android tablets. Acts as both the listening device and the display — shows the server's web UI in a full-screen WebView while capturing audio natively.

### Requirements

- Android 10+ (SDK 29)
- A physical device with a microphone

### Build & Install

```bash
cd client/android
./gradlew installDebug
```

### Setup

On first launch, enter the Grooveprint server URL (e.g. `http://10.0.1.9:8457`). The app connects and displays the web UI. Tap the microphone button to start listening.

The app captures audio via a foreground service and sends WAV chunks to the server every 3 seconds for matching.

### Remote Control

The app runs a local HTTP server on port **8458**:

- `POST /start` — start listening
- `POST /stop` — stop listening
- `GET /status` — current state

## Home Assistant

A [custom integration](https://github.com/leolobato/grooveprint-hass) exposes Grooveprint as a media player entity in Home Assistant. It connects to the server's SSE stream and the Android client's control service to provide:

- **Media player** — shows the current track with artist, album, and cover art
- **Status sensor** — `idle`, `listening`, or `playing` for use in automations
- **Listening switch** — toggle audio capture on the Android client remotely

Install via HACS or manually. Requires the server URL and the Android client's control URL during setup.

You could, for example, use a smart plug to detect when your turntable is on and start/stop listening automatically.

## License

MIT License. See [LICENSE](LICENSE).
