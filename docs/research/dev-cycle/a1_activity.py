#!/usr/bin/env python3
"""Sections 1-3: agent active time and tokens by activity; per ticket and per ticket type."""
import collections, statistics, json, os
from common import *

R = load_agents()
T = read_tickets()
out = []
def P(s=''): out.append(s)

# ---------- 1. time by activity
gen = collections.Counter(); tool = collections.Counter(); wait = collections.Counter()
for r in R:
    for (s, a), v in r['intervals'].items():
        g = group_of(a)
        if s == 'gen': gen[g] += v
        elif s == 'tool': tool[g] += v
        elif s == 'wait-bg': wait[g] += v
tot = sum(gen.values()) + sum(tool.values()) + sum(wait.values())
P('## A1. Agent active time by activity (all %d agent runs since 11-20)' % len(R))
P('Total active %.1f h = generation %.1f h + inside tools %.1f h + idle waiting for own background run %.1f h. '
  'Excluded: %.1f h over caps (gen>10 min, tool>60 min), %.1f h between turns (agent stopped, waiting for the lead).' % (
    tot / 3600, sum(gen.values()) / 3600, sum(tool.values()) / 3600, sum(wait.values()) / 3600,
    sum(r['excess'] for r in R) / 3600, sum(r['intervals'].get(('idle', 'between turns (waiting for lead)'), 0) for r in R) / 3600))
P()
P('| Activity | gen h | tool h | bg-wait h | total h | share |')
P('|---|---:|---:|---:|---:|---:|')
rows = sorted(GROUP_NAMES, key=lambda g: -(gen[g] + tool[g] + wait[g]))
for g in rows:
    t = gen[g] + tool[g] + wait[g]
    if t < 60: continue
    P('| %s | %.1f | %.1f | %.1f | %.1f | %.0f%% |' % (g, gen[g] / 3600, tool[g] / 3600, wait[g] / 3600, t / 3600, 100 * t / tot))
P()
big = collections.Counter()
for g in GROUP_NAMES: big[BIG[g]] += gen[g] + tool[g] + wait[g]
P('Families: ' + '; '.join('%s %.1f h (%.0f%%)' % (k, v / 3600, 100 * v / tot) for k, v in big.most_common()))
P()

# what the model was reacting to when it generated
react = collections.Counter()
for r in R:
    for (prev, act), v in r.get('react', {}).items():
        pg = 'test FAILED' if prev == 'test FAILED' else ('notification' if prev.startswith('notification') else group_of(prev) if prev != 'prompt' else 'prompt')
        react[(pg, group_of(act))] += v
byprev = collections.Counter()
for (p, a), v in react.items(): byprev[p] += v
gtot = sum(byprev.values())
P('### Generation time by what the model had just received (the input it was thinking about)')
P('| Previous result | gen h | share of gen | top next actions |')
P('|---|---:|---:|---|')
for p, v in byprev.most_common(12):
    nx = sorted(((vv, a) for (pp, a), vv in react.items() if pp == p), reverse=True)[:3]
    P('| %s | %.1f | %.0f%% | %s |' % (p, v / 3600, 100 * v / gtot, ', '.join('%s %.1f' % (a, vv / 3600) for vv, a in nx)))
P()

# ---------- 2. tokens by activity
tk = collections.defaultdict(collections.Counter)
for r in R:
    for a, d in r['tokens'].items():
        g = group_of(a)
        for k, v in d.items(): tk[g][k] += v
otot = sum(d['out'] for d in tk.values()); itot = sum(d['in'] + d['cache_read'] + d['cache_write'] for d in tk.values())
P('## A2. Tokens by activity (the message that produced the action)')
P('Output %.1f M tokens, input (incl. cache) %.0f M tokens. Visible output (tool inputs and text) is about chars/3.5; the rest of output is thinking.' % (otot / 1e6, itot / 1e6))
P()
P('| Activity | msgs | out k | out share | est. thinking share of its out | input M | cache-write M | time share |')
P('|---|---:|---:|---:|---:|---:|---:|---:|')
for g in sorted(tk, key=lambda g: -tk[g]['out']):
    d = tk[g]
    if d['out'] < 20000: continue
    vis = d['vis_chars'] / 3.5
    think = max(0, 1 - vis / d['out']) if d['out'] else 0
    t = gen[g] + tool[g] + wait[g]
    P('| %s | %d | %.0f | %.0f%% | %.0f%% | %.0f | %.1f | %.0f%% |' % (g, d['msgs'], d['out'] / 1000, 100 * d['out'] / otot, 100 * think,
        (d['in'] + d['cache_read'] + d['cache_write']) / 1e6, d['cache_write'] / 1e6, 100 * t / tot))
P()
# output tokens per second of generation, by model
spd = collections.defaultdict(lambda: [0, 0.0])
for r in R:
    o = sum(d['out'] for d in r['tokens'].values()); g = sum(v for (s, a), v in r['intervals'].items() if s == 'gen')
    m = (r.get('model') or '?').replace('claude-', '')
    spd[m][0] += o; spd[m][1] += g
P('Output tokens per second of generation time: ' + '; '.join('%s %.0f tok/s over %.1f h' % (m, o / max(g, 1), g / 3600) for m, (o, g) in spd.items() if g > 600))
P()

# ---------- 3. per ticket / type
runs = []
for r in R:
    tid = ticket_id(r['ticket'])
    meta = T.get(r['ticket']) if r['ticket'] else None
    if r['ticket'] and not meta:
        # moved/renamed ticket: match by id
        for k, v in T.items():
            if ticket_id(k) == tid: meta = v; break
    act = active(r)
    bl = sum(v for (s, a), v in r['intervals'].items() if s in ('gen', 'tool', 'wait-bg') and group_of(a) == 'Blender')
    typ = ttype(meta, r['ticket'], bl / act if act else 0) if r['ticket'] else 'no ticket (research/review)'
    toks = sum(d['out'] for d in r['tokens'].values())
    runs.append(dict(r=r, tid=tid or ('-' + r['meta'].get('description', r['id'])[:40]), meta=meta, act=act, typ=typ, out=toks,
                     model=r['meta'].get('model'), groups={g: 0 for g in GROUP_NAMES}))
    for (s, a), v in r['intervals'].items():
        if s in ('gen', 'tool', 'wait-bg'): runs[-1]['groups'][group_of(a)] += v
byt = collections.defaultdict(list)
for x in runs: byt[x['tid']].append(x)
tickets = []
for tid, xs in byt.items():
    g = collections.Counter()
    for x in xs: g.update(x['groups'])
    tickets.append(dict(tid=tid, runs=len(xs), act=sum(x['act'] for x in xs), typ=xs[0]['typ'], title=(xs[0]['meta'] or {}).get('title', xs[0]['tid']),
                        out=sum(x['out'] for x in xs), groups=g, models=sorted(set(str(x['model']) for x in xs)),
                        prompts=sum(len(x['r']['prompts']) for x in xs), wall=max(x['r']['last'] for x in xs) - min(x['r']['first'] for x in xs)))
tk_ = [t for t in tickets if not t['tid'].startswith('-')]
acts = [t['act'] / 60 for t in tk_]
P('## A3. Per ticket')
P('%d tickets had agent runs (%d runs); %d runs had no ticket (%.1f h). Active minutes per ticket: mean %.0f, median %.0f, p10 %.0f, p90 %.0f, max %.0f.' % (
    len(tk_), sum(t['runs'] for t in tk_), sum(1 for x in runs if x['tid'].startswith('-')), sum(x['act'] for x in runs if x['tid'].startswith('-')) / 3600,
    statistics.mean(acts), statistics.median(acts), pct(acts, .1), pct(acts, .9), max(acts)))
P()
P('| Type | tickets | runs | active h | mean min | median min | p90 min | tests % | read % | write code+tests % | shots % | blender % | git % | out tok k/ticket |')
P('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
typs = collections.defaultdict(list)
for t in tickets: typs[t['typ']].append(t)
def fam(g, names): return sum(g[n] for n in names)
TESTS = ('Tests: run.sh', 'Tests: agent_finish', 'Tests: check.sh', 'Tests: reading logs', 'Wait/poll loops, Monitor', 'Godot ad hoc runs', 'Lint/kit checks')
WRITE = ('Write game GDScript', 'Write test GDScript', 'Edit scene .tscn', 'Edit resource .tres', 'Other edits (config, data)')
for ty, ts_ in sorted(typs.items(), key=lambda x: -sum(t['act'] for t in x[1])):
    A = sum(t['act'] for t in ts_); m = [t['act'] / 60 for t in ts_]
    agg = collections.Counter()
    for t in ts_: agg.update(t['groups'])
    P('| %s | %d | %d | %.1f | %.0f | %.0f | %.0f | %.0f | %.0f | %.0f | %.0f | %.0f | %.0f | %.0f |' % (ty, len(ts_), sum(t['runs'] for t in ts_), A / 3600,
        statistics.mean(m), statistics.median(m), pct(m, .9), 100 * fam(agg, TESTS) / A, 100 * agg['Read/explore code'] / A,
        100 * fam(agg, WRITE) / A, 100 * agg['Shots and viewing stills'] / A, 100 * agg['Blender'] / A, 100 * agg['Git and commits'] / A,
        sum(t['out'] for t in ts_) / len(ts_) / 1000))
P()
P('### The 10 most expensive tickets (agent active time)')
P('| Ticket | type | runs | lead msgs to it | active h | wall h | top activities |')
P('|---|---|---:|---:|---:|---:|---|')
for t in sorted(tk_, key=lambda t: -t['act'])[:10]:
    top = ', '.join('%s %.1f' % (g, v / 3600) for g, v in t['groups'].most_common(4))
    P('| %s %s | %s | %d | %d | %.1f | %.0f | %s |' % (t['tid'], t['title'][:40], t['typ'], t['runs'], t['prompts'] - t['runs'], t['act'] / 3600, t['wall'] / 3600, top))
P()
json.dump([dict(tid=t['tid'], typ=t['typ'], runs=t['runs'], act=t['act'], title=t['title'], groups=dict(t['groups'])) for t in tickets],
          open(os.path.join(HERE, 'tickets.json'), 'w'))
open(os.path.join(HERE, 'a1.md'), 'w').write('\n'.join(out) + '\n')
print('\n'.join(out))
