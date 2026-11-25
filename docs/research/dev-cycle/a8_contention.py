#!/usr/bin/env python3
"""--touched/agent_finish durations by day and by how many other agents' test runs were going at its start;
share of suites --touched selects."""
import json, collections, statistics, re, os
from common import *
runs = json.load(open(os.path.join(HERE, 'testruns.json'))); R = load_agents()
tr = [(x['t'], x['t'] + x['dur'], x['agent']) for x in runs if x['dur']]
def others(t, ag): return sum(1 for a, b, g in tr if a < t <= b and g != ag)
out = ['| day | touched+finish runs (passing) | median s alone | median s with 1 other run going | with 2+ | --touched picked (median share of suites) | "every suite runs" |', '|---|---:|---:|---:|---:|---:|---:|']
sel = collections.defaultdict(list); every = collections.Counter(); nsel = collections.Counter()
for r in R:
    for c in r['calls']:
        if c['cat'] in ('test: run.sh', 'test: agent_finish') and (c['cat'] == 'test: agent_finish' or '--touched' in c['cmd']):
            o = c['out'] or ''; d = utc(c['t'])[:5]
            m = re.search(r'--touched: (\d+) of (\d+) suites', o)
            if m: sel[d].append(int(m.group(1)) / int(m.group(2))); nsel[d] += 1
            if 'every suite runs' in o: every[d] += 1; nsel[d] += 1
for d in sorted(set(utc(x['t'])[:5] for x in runs)):
    by = collections.defaultdict(list)
    for x in runs:
        if x['dur'] and x['sel'] in ('touched', 'agent_finish') and not x['failed'] and utc(x['t']).startswith(d):
            by[min(others(x['t'], x['agent']), 2)].append(x['dur'])
    n = sum(len(v) for v in by.values())
    f = lambda k: ('%.0f (n=%d)' % (statistics.median(by[k]), len(by[k]))) if by[k] else '-'
    out.append('| %s | %d | %s | %s | %s | %s | %d of %d |' % (d, n, f(0), f(1), f(2), ('%.0f%%' % (100 * statistics.median(sel[d]))) if sel[d] else '-', every[d], nsel[d]))
open(os.path.join(HERE, 'a8.md'), 'w').write('\n'.join(out) + '\n'); print('\n'.join(out))
