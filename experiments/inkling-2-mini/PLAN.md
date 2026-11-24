# Inkling 2 Mini on Apple M6 / 24 GB

## Targets
- c1 decode tok/s at 4k / 32k / 64k context, TTFT, prefill tok/s.
- Memory cap: ~18 GiB total for the server (leave room for macOS).
- Quality: AD-Q4_K (96.3% top-1 vs BF16). Uncensored = same base + AtomicChat LoRA.

## Reference numbers (not ours)
Atomic Engine, M4 Max 48 GB, 4k prompt, 64 tokens, greedy, DSpark Q8_0 draft:
Q4_K @14 GiB budget 49.85 tok/s, TTFT 11.09 s; stock llama.cpp 32.38 tok/s.
Source: engine/atomic-engine/docs/atomic-engine-inkling-m4-max-comparison.png

## Log
- 2026-11-24: repo created; skill installed; Atomic Engine submodule @ fb69fff. No runs yet.
