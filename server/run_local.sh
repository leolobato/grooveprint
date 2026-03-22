#!/usr/bin/env bash
# Run the grooveprint server locally without Docker (for debugging)
set -euo pipefail

cd "$(dirname "$0")"

# Use local venv if it exists, otherwise expect deps are installed globally
if [ -d "venv" ]; then
    source venv/bin/activate
fi

export GROOVEPRINT_DB_PATH="${GROOVEPRINT_DB_PATH:-./data/fingerprints.db}"
mkdir -p "$(dirname "$GROOVEPRINT_DB_PATH")"

exec uvicorn app.main:app --host 0.0.0.0 --port 8457 --reload
