#!/usr/bin/env bash
# Stop the server started by serve.sh (by pid, never by pattern). SIGTERM, then wait up to 60 s.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; P="$ROOT/.run/server.pid"
[ -f "$P" ] || exit 0; pid=$(cat "$P")
if kill -0 "$pid" 2>/dev/null; then
  kill -TERM "$pid"; for _ in $(seq 60); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  kill -0 "$pid" 2>/dev/null && { echo "server $pid did not exit in 60 s" >&2; exit 1; }
fi
rm -f "$P"
