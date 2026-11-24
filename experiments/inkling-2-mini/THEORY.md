# Ceilings: Inkling 2 Mini AD-Q4_K on Apple M6 (base, 12-core GPU, 24 GB)

## Measured hardware (tools/hwbench.swift, 2026-11-24, AC power)
- GPU read bandwidth 151.5 GB/s, copy (r+w) 153.8 GB/s
- fp16 GEMM 4096^3 via MPS: 18.73 TFLOPS
- Metal recommendedMaxWorkingSetSize 18,186 MiB (default wired limit); hw.memsize_usable 23.4 GiB
- Idle system memory in use (wired+active+compressed): ~7.5-8 GiB with normal apps open

## Model bytes (tools/gguf_bytes.py on AD-Q4_K, 16.514 GB)
- 24 layers; layers 6-17 run 3x -> 48 layer visits per token
- experts 0.616 GB/layer (128 experts, top-8) -> 0.0385 GB per layer visit
- dense/attention ~0.030 GB/layer (0.0325 in looped layers)
- output.weight 0.492 GB (vocab 201,024 x 2304), token_embd 0.492 GB (1 row read per token)

## Decode (c1), bandwidth bound
bytes/token = experts 48 x 0.0385 = 1.85 GB + dense 12 x 0.030 + 36 x 0.0325 = 1.53 GB + LM head 0.49 GB = ~3.87 GB
ceiling = 151.5 / 3.87 = ~39 tok/s (no speculation); practical (~75-80% of BW) ~30 tok/s.
Speculation with k drafts: verify reads the expert union for k+1 tokens (1-(15/16)^(k+1)) x 16 = 2.8x experts at k=2,
dense + head once; draft adds ~0.5 GB per draft step. At k=2 with 2.2 accepted/step: ~(5.2+1.5+1.0)/2.2 = ~3.5 GB/token
-> ~43 tok/s. Speculation gains little on this chip; the target is to cut bytes, not add drafts.
(Looped layers reuse weights across passes; whether passes hit the same experts is unmeasured. The SLC is too small to help.)

## Budget mode (SSD expert streaming)
With --engine-budget-mib below model size, cache misses read experts from SSD. Ceiling then also depends on SSD read rate (unmeasured).
Engine limitation in this preview: budget profile requires ctx <= 4096, ubatch <= 256, one sequence.

## Prefill, compute bound
FLOPs/token ~ 2 x 5.4B effective active = 10.8 GFLOP (+ attention, small at 4k). At 50% of 18.7 TFLOPS: ~870 tok/s.
Quantized matmul kernels rarely reach fp16 MPS peak; treat ~400-600 as a realistic target.

## KV
Full-attention layers 3, 11, 17, 23 (pattern) with loop passes: 8 global passes x 8 KV heads x 128 dim x 2 (K,V)
= 16,384 values/token -> 32 KB/token fp16, ~9 KB/token q4_0. 32k ctx: ~1 GB fp16 / ~0.3 GB q4_0. SWA layers: fixed 1024-token window.
