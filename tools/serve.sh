#!/usr/bin/env bash
# Start llama-server detached; extra args are passed through. Writes .run/server.pid, logs to .run/server.log.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; mkdir -p "$ROOT/.run"
BIN="${LLAMA_SERVER:-$ROOT/engine/atomic-engine/build-metal/bin/llama-server}"
nohup "$BIN" --host 127.0.0.1 --port 8080 --alias inkling-2-mini "$@" > "$ROOT/.run/server.log" 2>&1 < /dev/null &
echo $! > "$ROOT/.run/server.pid"
