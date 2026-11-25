#!/usr/bin/env python3
"""What agents read; poll loops; agent_finish after a green --touched; model comparison; hook refusals;
time per ticket stage (start-up, build, finish)."""
import re, json, os, collections, statistics
from common import *
R = load_agents()
runs = json.load(open(os.path.join(HERE, 'testruns.json')))
out = []
def P(s=''): out.append(s)

# ---- reads by target
def target_area(c):
    p = c['path'] if c['name'] in ('Read', 'Grep', 'Glob') else c['cmd']
    if c['name'] in ('Grep', 'Glob') and not p: p = ''
    for a, rx in (('reference/ (old game)', r'reference/'), ('kit/ docs+skills', r'kit/(docs|skills|agents)'), ('kit/ tools+tests', r'kit/(tools|tests)'),
                  ('docs/migration', r'docs/migration'), ('docs/architecture', r'docs/architecture'), ('tickets docs/llm', r'docs/llm'),
                  ('tests/', r'(^|[\s/])tests/'), ('game/', r'(^|[\s/])game/'), ('git output', r'\bgit\b'), ('/tmp logs', r'/tmp/')):
        if re.search(rx, p): return a
    return 'other/unclear'
gen_by = collections.Counter(); n_by = collections.Counter()
for r in R:
    # gen seconds per message id are in msgstats keyed by order; approximate by counting calls and using mean gen per read msg
    for c in r['calls']:
        if c['cat'] == 'read/explore':
            n_by[target_area(c)] += 1
tot = sum(n_by.values())
P('## A7. What the agents read (read/explore calls by target)')
P('%d read/explore calls (%.0f per ticket run). ' % (tot, tot / max(1, sum(1 for r in R if r['ticket']))) + ', '.join('%s %d (%.0f%%)' % (a, n, 100 * n / tot) for a, n in n_by.most_common()))
P()
# reads in the first 15 minutes of a run (orientation) vs later
early = 0; late = 0; early_t = 0.0
for r in R:
    if not r['ticket']: continue
    t0 = r['first']
    for c in r['calls']:
        if c['cat'] == 'read/explore':
            if c['t'] - t0 < 900: early += 1
            else: late += 1
P('Read calls in the first 15 min of a ticket run: %d (%.0f%%); later: %d.' % (early, 100 * early / (early + late), late))
# time to first edit
tfe = []
for r in R:
    if not r['ticket']: continue
    e = [c['t'] for c in r['calls'] if c['cat'].startswith('edit:') and 'docs/llm' not in c['path'] and 'docs/llm' not in c['cmd']]
    if e:
        # active time before first code edit
        t1 = e[0]
        tfe.append(sum(min(b, t1) - a for a, b, s in r['spans'] if a < t1))
P('Active time before the first non-ticket edit: median %.1f min, mean %.1f min, p90 %.1f min (n=%d): orientation cost per ticket.' % (
    statistics.median(tfe) / 60, statistics.mean(tfe) / 60, pct(tfe, .9) / 60, len(tfe)))
P()
# ---- poll loops
polls = [c for r in R for c in r['calls'] if c['cat'] == 'wait/poll']
pd = [(c['end'] or c['t']) - c['t'] for c in polls if not c['bg']]
P('## A8. Poll loops and waits')
P('wait/poll calls: %d (%d foreground, total %.1f h, median %.0f s; %d ran >= 590 s, i.e. hit the 10-min tool cap). Monitor calls: %d.' % (
    len(polls), len(pd), sum(pd) / 3600, statistics.median(pd) if pd else 0, sum(1 for x in pd if x >= 590), sum(1 for c in polls if c['name'] == 'Monitor')))
byday = collections.Counter()
for c in polls:
    byday[utc(c['t'])[:5]] += ((c['end'] or c['t']) - c['t'])
P('Poll time by day: ' + ', '.join('%s %.1f h' % (d, v / 3600) for d, v in sorted(byday.items())))
P()
# ---- agent_finish after a green touched with no edit
fin_dup = 0; fin_dup_t = 0.0; fin_n = 0
for i, x in enumerate(runs):
    if x['sel'] != 'agent_finish': continue
    fin_n += 1
    if i > 0 and runs[i - 1]['agent'] == x['agent'] and runs[i - 1]['sel'] in ('touched', 'whole suite') and runs[i - 1]['verdict'].startswith('PASS') and x['edits'] == 0:
        fin_dup += 1; fin_dup_t += x['dur'] or 0
P('agent_finish.sh right after a green --touched/whole run with no edit between: %d of %d calls, %.1f h. pass_stamp.py (in the kit since 11-25 20:40) now reuses exactly these.' % (fin_dup, fin_n, fin_dup_t / 3600))
fail_fin = [x for x in runs if x['sel'] == 'agent_finish' and x['failed']]
P('agent_finish runs that failed (suite red at commit time): %d.' % len(fail_fin))
P()
# ---- hook refusals and errors
ref = collections.Counter(); ref_t = 0.0
for r in R:
    for c in r['calls']:
        o = c['out'] or ''
        if re.search(r'Split it into plain, separate commands|hook_guard|refuses|refused', o[:400]):
            ref[c['cat']] += 1
ne = sum(1 for r in R for c in r['calls'] if c.get('err'))
P('Calls answered by a refusal (hook or tool guard) in the first lines of output: %d (%s). Tool calls with is_error: %d of %d.' % (
    sum(ref.values()), ', '.join('%s %d' % kv for kv in ref.most_common(5)), ne, sum(len(r['calls']) for r in R)))
P()
# ---- model comparison on feature tickets
tk = json.load(open(os.path.join(HERE, 'tickets.json')))
mm = collections.defaultdict(list)
mod = {}
for r in R:
    tid = ticket_id(r['ticket'])
    if tid: mod.setdefault(tid, set()).add(r['meta'].get('model'))
for t in tk:
    if t['tid'] in mod and len(mod[t['tid']]) == 1:
        mm[(t['typ'], list(mod[t['tid']])[0])].append(t['act'] / 60)
P('## A9. Model and ticket time (single-model tickets)')
P('| type | model | tickets | median min | mean min |')
P('|---|---|---:|---:|---:|')
for (ty, m), xs in sorted(mm.items()):
    if len(xs) >= 3: P('| %s | %s | %d | %.0f | %.0f |' % (ty, m, len(xs), statistics.median(xs), statistics.mean(xs)))
P()
# calls and messages per ticket
cpt = [len(r['calls']) for r in R if r['ticket']]
P('Tool calls per ticket run: median %d, mean %.0f, p90 %d. Each round trip costs about 1.8 s fixed plus output time (A1b).' % (statistics.median(cpt), statistics.mean(cpt), pct(cpt, .9)))
open(os.path.join(HERE, 'a5.md'), 'w').write('\n'.join(out) + '\n')
print('\n'.join(out))
