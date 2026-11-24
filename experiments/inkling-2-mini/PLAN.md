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
- 2026-11-24: engine built @ fb69fff (build 12625, Metal, static). Weights in models/inkling-2-mini:
  AtomicChat/Inkling-2-Mini-GGUF @ 309509848b3151419aa26d069eb03db57fd29a00 (AD-Q4_K 16,525,559,776 B; dspark Q8_0; mmproj F16)
  AtomicChat/Inkling-2-Mini-Uncensored-GGUF @ 40886ab636cabb4decf4998224f790b462ab048e (LoRA 43,805,184 B)
- 2026-11-24: full GPU residency (stock path, -ngl all, Q4_K, c 32768) FAILS: Metal kIOGPUCommandBufferCallbackErrorOutOfMemory,
  both at the default wired limit and at iogpu.wired_limit_mb=20480 (set by user, resets on reboot). Cause: 15.4 GiB weights +
  ~7.5 GiB idle system use > 23.4 GiB usable. Swap grew to ~1 GB before stop.
- 2026-11-24: Atomic Engine budget mode needs --cache-ram 0 --ctx-checkpoints 0 AND ctx <= 4096, ubatch <= 256, -np 1
  (engine preview limit). Not usable for long chats as-is. Candidate engine work: lift the 4k ctx limit.
- 2026-11-24: baseline budget14-q4k-c4k (AD-Q4_K, budget 14436 MiB, c 4096, no draft, temp 1.0):
  c1 decode median 17.55 tok/s [16.69..18.09], prefill 128.9 tok/s @ 2421 tokens. Output correct (17*23=391, palindrome fn).
  = ~45% of the 39 tok/s bandwidth ceiling (SSD streaming in the loop).
- 2026-11-24 A/B (partial; queue stopped so the user could chat): b14 (no draft) c1 16.71 [16.0..17.11], prefill 122.3;
  b14-ds2 (DSpark Q8_0, n-max 2) c1 13.84 [12.74..15.23], prefill 85.4. REJECT draft at n-max 2: -17% decode, -30% prefill.
  Matches THEORY.md (bandwidth-poor chip; verify reads ~2.8x experts, and under budget mode those extra experts miss to SSD).
  Not yet run: second b14 control, ds1, third control.
