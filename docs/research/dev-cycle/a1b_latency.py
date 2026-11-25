#!/usr/bin/env python3
"""Per-message generation latency: fixed cost per round trip vs per output token, by model and context size."""
import collections, statistics
from common import *
R = load_agents()
rows = collections.defaultdict(list)
for r in R:
    m = (r.get('model') or '?').replace('claude-', '')
    for g, o, ctx, act, t in r['msgstats']:
        if 0 < g < 600 and o > 0: rows[m].append((g, o, ctx))
def fit(xs):
    n = len(xs); mx = statistics.mean(o for g, o, c in xs); my = statistics.mean(g for g, o, c in xs)
    b = sum((o - mx) * (g - my) for g, o, c in xs) / sum((o - mx) ** 2 for g, o, c in xs)
    return my - b * mx, b
for m, xs in rows.items():
    if len(xs) < 200: continue
    a, b = fit(xs)
    small = [g for g, o, c in xs if o < 150]
    print('%-12s msgs %5d  gen s: median %.1f mean %.1f | fit: %.1f s per message + %.1f ms per output token (%.0f tok/s) | msgs with <150 out tokens: n=%d median %.1f s | ctx median %.0fk' % (
        m, len(xs), statistics.median(g for g, o, c in xs), statistics.mean(g for g, o, c in xs), a, b * 1000, 1 / b if b else 0, len(small), statistics.median(small), statistics.median(c for g, o, c in xs) / 1000))
    # by context size
    for lo, hi in ((0, 50e3), (50e3, 100e3), (100e3, 150e3), (150e3, 1e9)):
        sub = [x for x in xs if lo <= x[2] < hi]
        if len(sub) > 100:
            a2, b2 = fit(sub); print('     ctx %3dk-%3dk: n=%5d fixed %.1f s, %.1f ms/token' % (lo / 1000, min(hi, 999e3) / 1000, len(sub), a2, b2 * 1000))
allx = [x for xs in rows.values() for x in xs]
a, b = fit(allx)
print('ALL: %d msgs, fixed %.1f s/msg -> %.1f h of %.1f h gen is per-round-trip overhead' % (len(allx), a, a * len(allx) / 3600, sum(g for g, o, c in allx) / 3600))
