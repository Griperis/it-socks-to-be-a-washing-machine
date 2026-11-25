#!/usr/bin/env python3
"""Whole-suite durations over the days, from the background task outputs and lead scratch logs
that survive on disk (SLOW lines, verdict lines) plus SLOW lines quoted in the lead transcript."""
import glob, os, re, collections, pickle, statistics
from datetime import datetime
B = '/tmp/claude-1000/-c-Users-Gripe-personal-repositories-it-socks-to-be-a-washing-machine'
rows = {}
for f in glob.glob(B + '/*/tasks/*.output') + glob.glob(B + '/*/scratchpad/*.log'):
    try: s = open(f, errors='replace').read().replace('\\n', '\n')
    except Exception: continue
    sl = re.findall(r'SLOW the whole suite took (\d+)s', s)
    if not sl: continue
    v = re.findall(r'(?:PASS|FAIL) (?:\d+ of )?(\d+) checks, (\d+) cases', s)
    pr = re.findall(r'processes: (\d+) for (\d+) suites, (\d+) at a time; the longest (.+?) (\d+)s', s)
    mt = os.path.getmtime(f)
    rows[(int(sl[-1]), v[-1][1] if v else '?')] = (mt, int(sl[-1]), int(v[-1][1]) if v else None, pr[-1] if pr else None, os.path.basename(f), 'integrate' in s[:3000] or 'RESULT' in s)
# lead transcript SLOW mentions (deduped by value+cases)
D = pickle.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lead.pkl'), 'rb'))
for c in D['calls']:
    for m in re.finditer(r'SLOW the whole suite took (\d+)s', c['out'] or ''):
        k = (int(m.group(1)), '?')
        if not any(k[0] == kk[0] for kk in rows): rows[k] = (c['t'], int(m.group(1)), None, None, 'lead transcript', True)
day = collections.defaultdict(list)
out = ['| day | whole runs seen | median s | min s | max s | cases (max) | suites/processes (last) |', '|---|---:|---:|---:|---:|---:|---|']
for k, (t, s, cases, pr, f, integ) in sorted(rows.items(), key=lambda kv: kv[1][0]):
    day[datetime.utcfromtimestamp(t).strftime('%m-%d')].append((s, cases, pr))
for d in sorted(day):
    xs = day[d]; ss = [x[0] for x in xs]
    pr = [x[2] for x in xs if x[2]]
    out.append('| %s | %d | %.0f | %d | %d | %s | %s |' % (d, len(xs), statistics.median(ss), min(ss), max(ss), max([x[1] for x in xs if x[1]] or [0]) or '?',
        ('%s procs for %s suites, longest %s %ss' % (pr[-1][0], pr[-1][1], pr[-1][3], pr[-1][4])) if pr else ''))
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'a4.md'), 'w').write('\n'.join(out) + '\n')
print('\n'.join(out)); print(len(rows), 'distinct whole runs')
