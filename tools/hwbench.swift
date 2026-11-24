// Measures GPU memory bandwidth (read+write copy, and read-only reduce) and fp16 GEMM throughput via Metal/MPS.
import Metal
import MetalPerformanceShaders
import Foundation

let dev = MTLCreateSystemDefaultDevice()!
let q = dev.makeCommandQueue()!
let src = """
#include <metal_stdlib>
using namespace metal;
kernel void copy4(device const float4* a [[buffer(0)]], device float4* b [[buffer(1)]], uint i [[thread_position_in_grid]]) { b[i] = a[i]; }
kernel void read4(device const float4* a [[buffer(0)]], device float* out [[buffer(1)]], constant uint& n [[buffer(2)]],
                  uint i [[thread_position_in_grid]], uint g [[threads_per_grid]]) {
  float4 s = 0; for (uint k = i; k < n; k += g) s += a[k];
  if (s.x == 1234.5f) out[0] = s.y;  // keep the loads alive
}
"""
let lib = try! dev.makeLibrary(source: src, options: nil)
func pso(_ n: String) -> MTLComputePipelineState { try! dev.makeComputePipelineState(function: lib.makeFunction(name: n)!) }
let copy = pso("copy4"), rd = pso("read4")
let bytes = 1 << 30  // 1 GiB
let a = dev.makeBuffer(length: bytes, options: .storageModePrivate)!
let b = dev.makeBuffer(length: bytes, options: .storageModePrivate)!
let o = dev.makeBuffer(length: 16, options: .storageModeShared)!
var n4 = UInt32(bytes / 16)
func time(_ reps: Int, _ enc: (MTLComputeCommandEncoder) -> Void) -> Double {
  var best = 1e9
  for _ in 0..<reps {
    let cb = q.makeCommandBuffer()!; let e = cb.makeComputeCommandEncoder()!; enc(e); e.endEncoding()
    cb.commit(); cb.waitUntilCompleted(); best = min(best, cb.gpuEndTime - cb.gpuStartTime)
  }
  return best
}
let tc = time(10) { e in e.setComputePipelineState(copy); e.setBuffer(a, offset: 0, index: 0); e.setBuffer(b, offset: 0, index: 1)
  e.dispatchThreads(MTLSize(width: Int(n4), height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 256, height: 1, depth: 1)) }
let tr = time(10) { e in e.setComputePipelineState(rd); e.setBuffer(a, offset: 0, index: 0); e.setBuffer(o, offset: 0, index: 1)
  e.setBytes(&n4, length: 4, index: 2)
  e.dispatchThreads(MTLSize(width: 65536 * 4, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 256, height: 1, depth: 1)) }
print(String(format: "copy bandwidth (r+w): %.1f GB/s", 2 * Double(bytes) / tc / 1e9))
print(String(format: "read bandwidth:       %.1f GB/s", Double(bytes) / tr / 1e9))
// fp16 GEMM via MPS
let N = 4096
let rowBytes = N * 2
func mat() -> MPSMatrix { MPSMatrix(buffer: dev.makeBuffer(length: N * rowBytes, options: .storageModePrivate)!,
  descriptor: MPSMatrixDescriptor(rows: N, columns: N, rowBytes: rowBytes, dataType: .float16)) }
let A = mat(), B = mat(), C = mat()
let mm = MPSMatrixMultiplication(device: dev, transposeLeft: false, transposeRight: false, resultRows: N, resultColumns: N, interiorColumns: N, alpha: 1, beta: 0)
var best = 1e9
for _ in 0..<8 { let cb = q.makeCommandBuffer()!; for _ in 0..<4 { mm.encode(commandBuffer: cb, leftMatrix: A, rightMatrix: B, resultMatrix: C) }
  cb.commit(); cb.waitUntilCompleted(); best = min(best, (cb.gpuEndTime - cb.gpuStartTime) / 4) }
print(String(format: "fp16 GEMM 4096^3:     %.2f TFLOPS", 2 * pow(Double(N), 3) / best / 1e12))
print("GPU: \(dev.name), recommendedMaxWorkingSetSize: \(dev.recommendedMaxWorkingSetSize / 1_048_576) MiB")
