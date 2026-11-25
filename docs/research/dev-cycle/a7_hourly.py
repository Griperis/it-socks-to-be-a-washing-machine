#!/usr/bin/env python3
"""Hour by hour: agent-active minutes, agents alive, lead active minutes, designer-wait minutes."""
import collections, os
from datetime import datetime, timezone
from common import *
R = load_agents(); D = load_lead()
H = collections.defaultdict(lambda: collections.Counter())
def add(a, b, key, w=1.0):
    t = a
    while t < b:
        h = int(t // 3600); e = min(b, (h + 1) * 3600)
        H[h][key] += (e - t) * w; t = e
for r in R:
    for a, b, s in r['spans']: add(a, b, 'agent')
    # alive: first..last of each run (bounded per hour as presence)
for a, b, s, act in D['spans']:
    add(a, b, 'lead_ask' if act == 'ask designer' else 'lead')
for a, b, k, pl in D['waits']:
    add(a, min(b, a + 3600), 'wait_' + k.split()[0])
out = ['| hour (UTC) | agent-active min | mean agents active | lead active min | designer answering min (AskUserQuestion) | lead idle waiting designer min | lead idle waiting agents min |', '|---|---:|---:|---:|---:|---:|---:|']
for h in sorted(H):
    c = H[h]
    if sum(c.values()) < 60: continue
    out.append('| %s | %.0f | %.1f | %.0f | %.0f | %.0f | %.0f |' % (datetime.fromtimestamp(h * 3600, timezone.utc).strftime('%m-%d %H'), c['agent'] / 60, c['agent'] / 3600,
               c['lead'] / 60, c['lead_ask'] / 60, c['wait_designer'] / 60, c['wait_agent'] / 60))
open(os.path.join(HERE, 'a7.md'), 'w').write('\n'.join(out) + '\n')
# summary: hours with designer present (lead active or ask) and agent load
pres = [h for h in H if H[h]['lead'] + H[h]['lead_ask'] + H[h]['wait_designer'] > 600]
print('hours with the lead working:', len(pres), ' agent-active h in them %.1f, mean agents active %.2f' % (sum(H[h]['agent'] for h in pres) / 3600, sum(H[h]['agent'] for h in pres) / 3600 / len(pres)))
nolead = [h for h in H if h not in pres and H[h]['agent'] > 0]
print('hours without the lead but agents active:', len(nolead), '%.1f agent-h' % (sum(H[h]['agent'] for h in nolead) / 3600))
