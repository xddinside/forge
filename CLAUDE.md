# forge

- Hardware: Apple M6 (base), 24 GB unified memory, ~5.5 GB free disk as of 2026-11-24 (Steam games use ~140 GB). Keep model downloads lean; check `df -h /` before pulling.
- For speed work, use the `inference-optimisation` skill and keep its layout in `experiments/<model>/`.
- macOS caveats for the skill's scripts: `queue.sh` needs `flock` (not on macOS; `brew install flock` or port the lock). the skill's `mem.sh` is Linux/Docker-only: use `tools/mem.sh` (system-wide wired+active+compressed+swap; process footprints miss mmapped weights).
- Engine changes: work on a feature branch inside `engine/atomic-engine`, never on `engine-development` directly. Pin the submodule commit in this repo after each accepted change.
- Default macOS GPU wired limit (`iogpu.wired_limit_mb` = 0) caps Metal at a fraction of RAM; record any change to it in PLAN.md and restore it when done.
- Weights go in `models/` (git-ignored); pin HF revisions in configs.
- Launch/stop servers only via `tools/serve.sh` / `tools/stop.sh` (pid file in `.run/`); never pkill by pattern.
- Full-GPU AD-Q4_K does not fit (Metal OOM): ~7.5 GiB idle system use + 15.4 GiB weights > 23.4 GiB usable.
- Atomic Engine budget mode (`--engine-budget-mib`) requires `--cache-ram 0 --ctx-checkpoints 0`, `-c <= 4096`, `-ub <= 256`, `-np 1`.
- `tools/chat.html` is a minimal chat UI for the server on :8080 (open the file in a browser).
