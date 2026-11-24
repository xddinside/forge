# local-ai

Running and speeding up local LLMs on this Mac (Apple M6, 24 GB unified memory, macOS 27.2).

## Layout

| Path | What |
|---|---|
| `engine/atomic-engine` | Submodule: [Atomic Engine](https://github.com/AtomicBot-ai/atomic-engine) (MIT, llama.cpp fork with SSD expert streaming + DSpark drafting). Our changes go on branches here. |
| `.claude/skills/inference-optimisation` | [inference-optimisation skill](https://github.com/sybil-solutions/inference-optimisation-skill) @ fda968e: ceilings-first, A/B-with-controls hill-climbing. |
| `experiments/<model>/` | One dir per model: `PLAN.md`, `THEORY.md`, `ledger.jsonl`, `configs/`, `best-config.json` (the skill's layout). |
| `models/` | GGUF weights. Git-ignored. |

## Current target

Inkling 2 Mini (AtomicChat AD-Q4_K + Uncensored LoRA + DSpark Q8_0 draft) via Atomic Engine on Metal.
See `experiments/inkling-2-mini/PLAN.md`.
