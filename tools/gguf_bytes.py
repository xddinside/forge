"""Sum GGUF tensor bytes by layer and kind, to compute bytes read per decoded token."""
import sys, re, collections
sys.path.insert(0, sys.argv[1])  # engine's gguf-py
from gguf import GGUFReader
r = GGUFReader(sys.argv[2])
for k in r.fields:
    if any(s in k for s in ("block_count", "expert_count", "expert_used", "loop", "embedding_length", "context_length", "head_count", "vocab", "sliding")):
        f = r.fields[k]
        try: v = f.parts[f.data[0]].tolist() if len(f.data) == 1 else [f.parts[i].tolist() for i in f.data][:30]
        except Exception: v = "?"
        print("META", k, v)
per = collections.defaultdict(lambda: collections.Counter())
glob = collections.Counter()
for t in r.tensors:
    m = re.match(r"blk\.(\d+)\.(.*)", t.name)
    kind = "expert" if m and "_exps" in t.name else "other"
    if m: per[int(m.group(1))][kind] += t.n_bytes
    else: glob[t.name] += t.n_bytes
print("GLOBAL", {k: round(v / 1e9, 3) for k, v in glob.most_common(8)})
for L in sorted(per): print("L%02d expert %.3f GB other %.4f GB" % (L, per[L]["expert"] / 1e9, per[L]["other"] / 1e9))
print("TOTAL %.3f GB" % (sum(t.n_bytes for t in r.tensors) / 1e9))
