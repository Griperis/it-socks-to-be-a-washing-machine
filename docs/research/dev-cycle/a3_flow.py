#!/usr/bin/env python3
"""Sections 4-5: rework (respawns, send-backs, conflicts) and waiting/flow: ticket lifecycle
(filed -> spawned -> agent done -> merged), merge rounds, real parallelism, the lead's waits."""
import re, os, json, collections, statistics, pickle
from datetime import datetime
from common import *

R = load_agents(); D = load_lead()
out = []
def P(s=''): out.append(s)
def iso(s): return datetime.fromisoformat(s).timestamp()

# ---- merges from git
merges = []
for ln in open(os.path.join(HERE, 'merges.txt')):
    h, c, a, subj = ln.rstrip('\n').split('|', 3)
    m = re.match(r'Merge (\S+)$', subj)
    if not m or m.group(1).startswith(('main', 'integrate')): continue
    br = m.group(1)
    k = re.match(r'([a-z]+)/(\d+)', br)
    merges.append(dict(t=iso(c), branch=br, tid=('%s/%s' % (k.group(1), k.group(2).lstrip('0') or '0')) if k else br))
merges.sort(key=lambda x: x['t'])
# ---- ticket filed times
filed = {}
cur = None
for ln in open(os.path.join(HERE, 'ticket_adds.txt')):
    ln = ln.strip()
    if ln.startswith('C|'): cur = iso(ln[2:])
    elif 'issues/' in ln:
        tid = ticket_id(ln)
        if tid: filed[tid] = min(filed.get(tid, 1e12), cur)
# ---- agent runs per ticket
byt = collections.defaultdict(list)
for r in R:
    tid = ticket_id(r['ticket'])
    if tid: byt[tid].append(r)

# ---- rework: respawns, send-backs
P('## A5. Rework')
multi = {t: rs for t, rs in byt.items() if len(rs) > 1}
P('Respawned tickets (more than one agent run): %d tickets, %d extra runs, %.1f h active in the extra runs.' % (
    len(multi), sum(len(rs) - 1 for rs in multi.values()), sum(active(r) for rs in multi.values() for r in sorted(rs, key=lambda r: r['first'])[1:]) / 3600))
# send-backs: later prompts (SendMessage continuations) into a run; active time after the 2nd prompt
sb_runs = 0; sb_msgs = 0; sb_time = 0.0
for r in R:
    ps = [t for t, p in r['prompts']]
    if len(ps) > 1:
        sb_runs += 1; sb_msgs += len(ps) - 1
        t2 = ps[1]
        sb_time += sum(min(b - a, 3600) for a, b, s in r['spans'] if a >= t2)
P('Lead messages into a running or finished agent (SendMessage: send-backs, answers, merges of main): %d runs got %d messages; active time after the first such message %.1f h (%.0f%% of all agent time).' % (
    sb_runs, sb_msgs, sb_time / 3600, 100 * sb_time / sum(active(r) for r in R)))
def mclass(p):
    q = p.lower()
    if re.search(r'killed|resuming|session ended|stop last night|doesn.t show as a running', q): return 'restart after an interruption'
    if re.search(r'damaged|uids godot would not write', q): return 'tool/git damage repair'
    if re.search(r'protocol|refs/heads/main|is on main|is merged|merged on main|merge main|merging to main|rebase|main at|main moved|conflict|taken on main|committed to main', q): return 'main changed: merge it in / renumber'
    if re.search(r'answer|designer.{0,40}(said|says|go|feedback|asked|chose|picked)|q\d{4}: go|first still', q): return 'designer answer / look feedback'
    if re.search(r'before the merge|fix|wrong|missing|not (yet )?done|redo|please add|drops|send.?back|still fails|fail', q): return 'send-back: fix before merge'
    if re.search(r'merged on main|is merged|merge main|rebase|main at|main moved|conflict', q): return 'main changed: merge it in'
    if re.search(r'rule|q\d{4}', q): return 'new rule / decision'
    if re.search(r'continue|go on|resume|carry on|status', q): return 'continue / status'
    return 'other'
cls = collections.defaultdict(lambda: [0, 0.0])
for r in R:
    ps = r['prompts'][1:]
    for k, (t, p) in enumerate(ps):
        t_next = ps[k + 1][0] if k + 1 < len(ps) else 1e12
        tm = sum(min(b, t_next) - a for a, b, s in r['spans'] if a >= t and a < t_next)
        c = mclass(p); cls[c][0] += 1; cls[c][1] += tm
P('| Lead message into an agent, by kind | messages | agent active h after it |')
P('|---|---:|---:|')
for c, (n, tm) in sorted(cls.items(), key=lambda kv: -kv[1][1]): P('| %s | %d | %.1f |' % (c, n, tm / 3600))
# lead SendMessage purposes (first words)
sm = [c for c in D['calls'] if c['name'] == 'SendMessage']
P('Lead SendMessage calls: %d.' % len(sm))
# conflicts and merge outcomes from the lead's integrate calls
ic = [c for c in D['calls'] if c['name'] == 'Bash' and re.search(r'integrate\.sh', c['cmd'])]
res = collections.Counter()
for c in D['calls']:
    for m in re.finditer(r'RESULT (MERGED|FAILED: \w+)', c['out'] or ''):
        res[m.group(1)] += 1
P('integrate.sh calls by the lead: %d (%d in the background). RESULT lines the lead saw: %s.' % (len(ic), sum(c['bg'] for c in ic), ', '.join('%s %d' % kv for kv in res.most_common(8))))
# lead time spent on merging: integrate tool time + lead gen/tool spans tagged merge or git between a FAILED and next MERGED
lead_merge = sum(b - a for a, b, s, act in D['spans'] if act in ('merge',))
lead_git = sum(b - a for a, b, s, act in D['spans'] if act in ('git',))
P('Lead time on integrate.sh (its own generation plus foreground calls): %.1f h; on other git: %.1f h.' % (lead_merge / 3600, lead_git / 3600))
# conflict windows: from a 'RESULT FAILED: conflict' result to the next 'RESULT MERGED'
fails = []
for c in D['calls']:
    o = c['out'] or ''
    if re.search(r'RESULT FAILED: conflict', o): fails.append(('F', c['end'] or c['t']))
    elif re.search(r'RESULT MERGED', o): fails.append(('M', c['end'] or c['t']))
fails.sort(key=lambda x: x[1])
wins = []; i = 0
while i < len(fails):
    if fails[i][0] == 'F':
        j = i
        while j < len(fails) and fails[j][0] != 'M': j += 1
        if j < len(fails): wins.append((fails[i][1], fails[j][1]))
        i = j + 1
    else: i += 1
wl = [b - a for a, b in wins]
act_in = sum(min(b, w1) - max(a, w0) for w0, w1 in wins for a, b, s, act in D['spans'] if b > w0 and a < w1)
P('Conflict stops: %d windows from a conflict RESULT to the next MERGED; wall median %.0f min, total %.1f h; the lead\'s active time inside them %.1f h.' % (
    len(wins), statistics.median(wl) / 60 if wl else 0, sum(wl) / 3600, act_in / 3600))
P()

# ---- flow: ticket lifecycle
P('## A6. Flow and waiting')
life = []
for m in merges:
    rs = byt.get(m['tid'])
    if not rs: continue
    rs = sorted(rs, key=lambda r: r['first'])
    spawn = rs[0]['first']
    # agent done: the last agent event before the merge
    done = max(min(r['last'], m['t']) for r in rs)
    # end of the first run's first turn (its first report)
    f = filed.get(m['tid'])
    life.append(dict(tid=m['tid'], filed=f, spawn=spawn, done=done, merged=m['t'], act=sum(active(r) for r in rs),
                     wall_build=done - spawn))
def med(xs): return statistics.median(xs) if xs else 0
q = [x['spawn'] - x['filed'] for x in life if x['filed'] and x['spawn'] > x['filed']]
b = [x['done'] - x['spawn'] for x in life]
w = [x['merged'] - x['done'] for x in life if x['merged'] >= x['done']]
a = [x['act'] for x in life]
P('Merged tickets with an agent run: %d. Per ticket, median (mean): filed->spawned %.1f h (%.1f); spawned->agent done %.0f min (%.0f), of which active %.0f min (%.0f); agent done->merged %.1f h (%.1f).' % (
    len(life), med(q) / 3600, statistics.mean(q) / 3600 if q else 0, med(b) / 60, statistics.mean(b) / 60, med(a) / 60, statistics.mean(a) / 60, med(w) / 3600, statistics.mean(w) / 3600))
P('Share of an average ticket\'s life (filed to merged): queue before spawn %.0f%%, agent building %.0f%%, waiting to merge %.0f%%.' % tuple(
    100 * x / (statistics.mean(q) + statistics.mean(b) + statistics.mean(w)) for x in (statistics.mean(q), statistics.mean(b), statistics.mean(w))))
P()
# merge rounds: merges within 45 min of each other
rounds = []
for m in merges:
    if rounds and m['t'] - rounds[-1][-1]['t'] < 45 * 60: rounds[-1].append(m)
    else: rounds.append([m])
P('### Merge rounds (merges less than 45 min apart), wall clock against agent hours')
P('| round (UTC) | tickets | first filed -> last merged h | first spawn -> last merged h | agent active h | longest ticket active h | parallelism (agent h / spawn->agent-done h) |')
P('|---|---:|---:|---:|---:|---:|---:|')
rt = []
for rd in rounds:
    ls = [x for x in life if any(x['tid'] == m['tid'] and abs(x['merged'] - m['t']) < 1 for m in rd)]
    if not ls: continue
    f0 = min((x['filed'] for x in ls if x['filed']), default=None)
    s0 = min(x['spawn'] for x in ls); d1 = max(x['done'] for x in ls); m1 = max(x['merged'] for x in ls)
    A = sum(x['act'] for x in ls)
    rt.append((len(ls), A, d1 - s0, m1 - s0))
    P('| %s | %d | %s | %.1f | %.1f | %.1f | %.1f |' % (utc(rd[0]['t']), len(ls), ('%.1f' % ((m1 - f0) / 3600)) if f0 else '?', (m1 - s0) / 3600, A / 3600,
        max(x['act'] for x in ls) / 3600, A / max(d1 - s0, 1)))
P()
# concurrency of agent activity (sweep)
ev = []
for r in R:
    for a0, b0, s in r['spans']:
        if b0 > a0: ev.append((a0, 1)); ev.append((b0, -1))
ev.sort()
cur = 0; last = None; hist = collections.Counter()
for t, d in ev:
    if last is not None and cur > 0: hist[cur] += t - last
    cur += d; last = t
busy = sum(hist.values()); tot = sum(k * v for k, v in hist.items())
P('Real parallelism: some agent was active %.1f h of wall clock; mean agents active at once in that time %.2f; time with 1 agent %.0f%%, 2 %.0f%%, 3 %.0f%%, 4+ %.0f%%.' % (
    busy / 3600, tot / busy, 100 * hist[1] / busy, 100 * hist[2] / busy, 100 * hist[3] / busy, 100 * sum(v for k, v in hist.items() if k >= 4) / busy))
# agent runs alive (first->last) concurrency for comparison
ev2 = sorted([(r['first'], 1) for r in R] + [(r['last'], -1) for r in R])
cur = 0; last = None; h2 = collections.Counter()
for t, d in ev2:
    if last is not None and cur > 0: h2[cur] += t - last
    cur += d; last = t
P('Lead session wall clock %.1f h; of it, some agent was active %.0f%%.' % ((D['last'] - D['first']) / 3600, 100 * busy / (D['last'] - D['first'])))
P()
# ---- lead waits
P('### The lead\'s time')
iv = collections.Counter()
for (s, a), v in D['iv'].items(): iv[s] += v
P('Lead active (generation + tools): %.1f h, of which AskUserQuestion open (the designer answering) %.1f h.' % ((iv['gen'] + iv['tool']) / 3600, D['iv'].get(('tool', 'ask designer'), 0) / 3600))
wt = collections.defaultdict(lambda: [0, 0.0, 0.0])
for a0, b0, k, pl in D['waits']:
    wt[k][0] += 1; wt[k][1] += b0 - a0; wt[k][2] += min(b0 - a0, 3600)
for k, (n, s, sc) in wt.items():
    P('- idle, then woken by %s: %d times, %.1f h (%.1f h with each gap capped at 60 min)' % (k, n, s / 3600, sc / 3600))
# lead idle while no agent active -> waiting on the designer only
def agents_active(t0, t1):
    return sum(max(0, min(b, t1) - max(a, t0)) for r in R for a, b, s in r['spans'] if b > t0 and a < t1)
idle_designer_noagents = 0.0; idle_designer_agents = 0.0
for a0, b0, k, pl in D['waits']:
    if k != 'designer': continue
    b1 = min(b0, a0 + 3600)
    x = agents_active(a0, b1)
    if x > 0.1 * (b1 - a0): idle_designer_agents += b1 - a0
    else: idle_designer_noagents += b1 - a0
P('Of the designer waits (capped): %.1f h with no agent working (everything waited on the designer), %.1f h while agents worked.' % (
    idle_designer_noagents / 3600, idle_designer_agents / 3600))
lt = collections.Counter()
for (s, a), v in D['iv'].items(): lt[a] += v
P('Lead active time by activity: ' + ', '.join('%s %.1f h' % (a, v / 3600) for a, v in lt.most_common(10)))
P()
open(os.path.join(HERE, 'a3.md'), 'w').write('\n'.join(out) + '\n')
print('\n'.join(out))
