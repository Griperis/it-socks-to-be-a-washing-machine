#!/usr/bin/env python3
"""Sections 4 and 6: every test run by the agents (foreground and background), its duration,
selection, verdict, the edits before it; fail cycles; repeats with no change; suite-time trend."""
import re, json, collections, statistics, os
from common import *
from datetime import datetime

R = load_agents()
tix = {t['tid']: t for t in json.load(open(os.path.join(HERE, 'tickets.json')))}
VERD = re.compile(r'^(?:\d+:)?(?:suite: )?(PASS \d+ checks, \d+ cases.*|FAIL \d+ of \d+ checks, \d+ cases.*|TIMED OUT.*|FAIL import.*|FAIL check.*|FAIL wiring.*)$', re.M)
out = []
def P(s=''): out.append(s)

def selection(c):
    cmd = c['cmd']
    if c['cat'] == 'test: agent_finish': return 'agent_finish' + (' --no-test' if '--no-test' in cmd else '')
    if c['cat'] == 'test: check.sh': return 'check.sh only'
    n = len(re.findall(r'run\.(sh|py)', cmd))
    loop = bool(re.search(r'\bfor \w+ in|seq \d|while ', cmd)) or n > 2
    if loop: return 'repeat loop'
    if re.search(r'--only=|--grep=', cmd): return 'targeted (--only/--grep)'
    if re.search(r'--touched|--changed', cmd): return 'touched'
    if re.search(r'--list|--help|--ledger', cmd): return 'list/help'
    return 'whole suite'

runs = []
for r in R:
    calls = r['calls']
    tid = ticket_id(r['ticket']) or '-'
    prev_t = None
    for k, c in enumerate(calls):
        if not c['cat'].startswith('test:'): continue
        sel = selection(c)
        if sel == 'list/help': continue
        end = c['notif'] if c['bg'] else c['end']
        dur = (end - c['t']) if end else None
        text = c['out'] or ''
        if c['bg']:
            # verdict is read later: first later call output with a verdict line
            text = ''
            for c2 in calls[k + 1:k + 15]:
                if c['notif'] and c2['t'] < c['notif']: continue
                if VERD.search(c2['out'] or ''): text = c2['out']; break
        v = VERD.findall(text)
        verdict = v[-1] if v else ('reused' if 'reused' in text else '?')
        failed = bool(re.match(r'FAIL|TIMED OUT', verdict)) or 'SCRIPT ERROR' in text
        if verdict == '?' and c['bg'] and c.get('nstat') and c['nstat'].split()[-1:] not in (['0'], ['completed']):
            pass
        # edits since the previous test run in this agent
        edits = 0
        if runs and runs[-1]['agent'] == r['id']:
            lo = runs[-1]['t']
            for c2 in calls:
                if lo < c2['t'] < c['t'] and (c2['cat'].startswith('edit:') or c2['cat'] == 'blender'): edits += 1
                if lo < c2['t'] < c['t'] and c2['name'] == 'Bash' and c2.get('writes') and not c2['cat'].startswith('edit:'): edits += 1
        else:
            edits = None
        same_cmd_edit = bool(c.get('writes'))
        refused = 'Split it into plain, separate commands' in (c['out'] or '') or 'hook' in (c['out'] or '')[:200].lower() and 'refus' in (c['out'] or '').lower()
        slot = sum(int(x) for x in re.findall(r'waited (\d+)s for a test slot', text))
        mirror_wait = len(re.findall(r'another run is using', text))
        slow = re.findall(r'SLOW the whole suite took (\d+)s', text)
        cases = re.search(r'(?:PASS|FAIL) (?:\d+ of )?(\d+) checks, (\d+) cases', verdict)
        runs.append(dict(agent=r['id'], tid=tid, t=c['t'], dur=dur, bg=c['bg'], sel=sel, verdict=verdict, failed=failed,
                         edits=edits, same_cmd_edit=same_cmd_edit, slot=slot, mirror_wait=mirror_wait,
                         slow=int(slow[0]) if slow else None, cases=int(cases.group(2)) if cases else None,
                         nocheck='--no-check' in c['cmd'], untouched='no suite is touched' in verdict,
                         reused='reused' in text, refused=refused, cmd=c['cmd'][:160], model=r['meta'].get('model')))
json.dump(runs, open(os.path.join(HERE, 'testruns.json'), 'w'))

timed = [x for x in runs if x['dur'] is not None]
P('## A4. Test runs by the agents')
P('%d test commands (run.sh, check.sh, agent_finish.sh) in %d agent runs; %d in the background. With a measured end: %d (%.1f h wall in total). '
  'Background runs are timed from the call to their task-notification.' % (
    len(runs), len(set(x['agent'] for x in runs)), sum(x['bg'] for x in runs), len(timed), sum(x['dur'] for x in timed) / 3600))
P()
P('| Selection | runs | bg | total h | median s | p90 s | max s | failed | verdict unknown |')
P('|---|---:|---:|---:|---:|---:|---:|---:|---:|')
by = collections.defaultdict(list)
for x in runs: by[x['sel']].append(x)
for s, xs in sorted(by.items(), key=lambda kv: -sum(x['dur'] or 0 for x in kv[1])):
    d = [x['dur'] for x in xs if x['dur'] is not None]
    P('| %s | %d | %d | %.1f | %.0f | %.0f | %.0f | %d | %d |' % (s, len(xs), sum(x['bg'] for x in xs), sum(d) / 3600, statistics.median(d) if d else 0,
        pct(d, .9), max(d) if d else 0, sum(x['failed'] for x in xs), sum(x['verdict'] == '?' for x in xs)))
P()
fg = [x['dur'] for x in timed if not x['bg']]; bgd = [x['dur'] for x in timed if x['bg']]
P('Foreground runs: %d, median %.0f s, total %.1f h. Background runs: %d timed, median %.0f s, total %.1f h.' % (
    len(fg), statistics.median(fg), sum(fg) / 3600, len(bgd), statistics.median(bgd), sum(bgd) / 3600))
# overhead: untouched runs = mirror + import + parse check + wiring check
un = [x['dur'] for x in timed if x['untouched'] and not x['bg']]
P('Fixed overhead of a run (mirror sync, import, parse check, wiring check): runs that selected no suite ("PASS 0 checks, 0 cases") took median %.0f s (n=%d, p90 %.0f s).' % (
    statistics.median(un) if un else 0, len(un), pct(un, .9)))
tg = [x for x in timed if x['sel'].startswith('targeted') and not x['bg'] and not x['failed']]
a = [x['dur'] for x in tg if x['nocheck']]; b = [x['dur'] for x in tg if not x['nocheck']]
P('Targeted runs (--only/--grep, passing, foreground): with the checks median %.0f s (n=%d), with --no-check median %.0f s (n=%d): the checks cost about %.0f s a run.' % (
    statistics.median(b) if b else 0, len(b), statistics.median(a) if a else 0, len(a), (statistics.median(b) - statistics.median(a)) if a and b else 0))
fin = [x for x in runs if x['sel'] == 'agent_finish']
P('agent_finish.sh: %d calls; %d said "reused" (no suite run), %d ran the suites. Median %.0f s when reused, %.0f s otherwise.' % (
    len(fin), sum(x['reused'] for x in fin), sum(not x['reused'] for x in fin),
    statistics.median([x['dur'] for x in fin if x['reused'] and x['dur']] or [0]), statistics.median([x['dur'] for x in fin if not x['reused'] and x['dur']] or [0])))
sw = [x for x in runs if x['slot']]
P('Slot waits printed ("waited Ns for a test slot"): %d runs, %.1f h in total (only foreground output is seen, so this is a floor). "another run is using the mirror": %d runs.' % (
    len(sw), sum(x['slot'] for x in sw) / 3600, sum(1 for x in runs if x['mirror_wait'])))
P()
# no-change repeats
rep = [x for x in runs if x['edits'] == 0 and not x['same_cmd_edit'] and x['sel'] not in ('agent_finish', 'agent_finish --no-test')]
rep_after_pass = [x for x in rep if True]
P('### Repeated runs with no file change in between')
P('%d of %d runs (%.0f%%) came after another run in the same agent with no edit in between (Write/Edit, sed -i, python writes, Blender). Their time: %.1f h. By selection: %s.' % (
    len(rep), len(runs), 100 * len(rep) / len(runs), sum(x['dur'] or 0 for x in rep) / 3600,
    ', '.join('%s %d' % kv for kv in collections.Counter(x['sel'] for x in rep).most_common())))
# why: after a pass (re-check), after a fail (flaky check), loops
prevv = {}
cnt = collections.Counter()
for i, x in enumerate(runs):
    if x in rep:
        p = runs[i - 1]
        cnt['after a FAIL (re-run to see if flaky / read more)' if p['failed'] else 'after a PASS' if p['verdict'].startswith('PASS') else 'after an unknown verdict'] += 1
P('Previous verdict: ' + ', '.join('%s %d' % kv for kv in cnt.most_common()))
P()
# fail cycles per ticket
P('### Fail-fix cycles (a failing run, then edits, then the next run)')
cyc = []
per_t = collections.Counter(); per_t_runs = collections.Counter()
for i, x in enumerate(runs):
    per_t_runs[x['tid']] += 1
    if x['failed'] and i + 1 < len(runs) and runs[i + 1]['agent'] == x['agent']:
        nx = runs[i + 1]
        cyc.append(dict(tid=x['tid'], len=nx['t'] - x['t'] + (nx['dur'] or 0), fix=nx['t'] - (x['t'] + (x['dur'] or 0)), run=x['dur'] or 0, edits=nx['edits']))
        per_t[x['tid']] += 1
P('%d fail-fix cycles in %d tickets. A cycle (failed run start to the end of the next run): median %.1f min, mean %.1f min, total %.1f h; of which the failing runs %.1f h, diagnosing and fixing %.1f h.' % (
    len(cyc), len(per_t), statistics.median([c['len'] for c in cyc]) / 60, statistics.mean([c['len'] for c in cyc]) / 60, sum(c['len'] for c in cyc) / 3600,
    sum(c['run'] for c in cyc) / 3600, sum(c['fix'] for c in cyc) / 3600))
dist = collections.Counter(min(per_t[t], 6) for t in per_t_runs if t != '-')
P('Cycles per ticket: ' + ', '.join('%s%s: %d tickets' % (k, '+' if k == 6 else '', dist.get(k, 0)) for k in range(0, 7)))
P('Top tickets by cycles: ' + ', '.join('%s %d' % kv for kv in per_t.most_common(8)))
P()
# runs per ticket
rpt = [per_t_runs[t] for t in per_t_runs if t != '-']
P('Test commands per ticket: mean %.1f, median %d, p90 %d, max %d (%s).' % (statistics.mean(rpt), statistics.median(rpt), pct(rpt, .9), max(rpt), max(per_t_runs, key=per_t_runs.get)))
P()
# whole-suite trend: whole runs by agents (fg, timed, cases>200) + SLOW lines
P('### Whole-suite time by day (agents\' whole runs and SLOW lines)')
day = collections.defaultdict(list)
for x in timed:
    if x['sel'] in ('whole suite',) and x['cases'] and x['cases'] > 100 and not x['bg']:
        day[datetime.utcfromtimestamp(x['t']).strftime('%m-%d')].append((x['dur'], x['cases']))
    elif x['slow']:
        day[datetime.utcfromtimestamp(x['t']).strftime('%m-%d')].append((x['slow'], x['cases'] or 0))
for d in sorted(day):
    xs = day[d]
    P('- %s: n=%d, median %.0f s, max %.0f s, cases up to %d' % (d, len(xs), statistics.median(x[0] for x in xs), max(x[0] for x in xs), max(x[1] for x in xs)))
P()
open(os.path.join(HERE, 'a2.md'), 'w').write('\n'.join(out) + '\n')
print('\n'.join(out))
