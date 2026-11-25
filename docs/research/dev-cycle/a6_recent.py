#!/usr/bin/env python3
"""Per-ticket averages for recent runs (since 11-24), the basis of the per-batch savings estimates."""
import json, collections, statistics, os
from datetime import datetime, timezone
from common import *
SINCE = datetime(2026, 11, 24, tzinfo=timezone.utc).timestamp()
R = [r for r in load_agents() if r['ticket'] and r['first'] >= SINCE]
runs = [x for x in json.load(open(os.path.join(HERE, 'testruns.json'))) if x['t'] >= SINCE and x['tid'] != '-']
n = len(set(ticket_id(r['ticket']) for r in R))
g = collections.Counter()
for r in R:
    for (s, a), v in r['intervals'].items():
        if s in ('gen', 'tool', 'wait-bg'): g[group_of(a)] += v
A = sum(g.values())
out = ['## A10. Recent per-ticket profile (agent runs started 11-24 or later: %d runs, %d tickets)' % (len(R), n),
       'Active per ticket %.0f min. Per ticket: ' % (A / n / 60) + ', '.join('%s %.1f min' % (k, v / n / 60) for k, v in g.most_common(10))]
by = collections.defaultdict(list)
for x in runs: by[x['sel']].append(x)
for s, xs in by.items():
    d = [x['dur'] for x in xs if x['dur']]
    out.append('- %s: %.1f runs per ticket, median %.0f s, %.1f min per ticket' % (s, len(xs) / n, statistics.median(d) if d else 0, sum(d) / n / 60))
open(os.path.join(HERE, 'a6.md'), 'w').write('\n'.join(out) + '\n'); print('\n'.join(out))
