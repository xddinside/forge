# forge

- Hardware: Apple M6 (base), 24 GB unified memory, ~35 GB free disk. Keep model downloads lean; check `df -h /` before pulling.
- For speed work, use the `inference-optimisation` skill and keep its layout in `experiments/<model>/`.
- macOS caveats for the skill's scripts: `queue.sh` needs `flock` (not on macOS; `brew install flock` or port the lock). `mem.sh` is Linux/Docker-only: measure memory with `footprint`/`vmmap`/`ioreg` and the server's own reporting instead.
- Engine changes: work on a feature branch inside `engine/atomic-engine`, never on `engine-development` directly. Pin the submodule commit in this repo after each accepted change.
- Default macOS GPU wired limit (`iogpu.wired_limit_mb` = 0) caps Metal at a fraction of RAM; record any change to it in PLAN.md and restore it when done.
- Weights go in `models/` (git-ignored); pin HF revisions in configs.
