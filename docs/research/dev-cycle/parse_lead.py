#!/usr/bin/env python3
"""Parse the lead transcript (streamed) into lead.pkl: intervals by state/activity, every tool
call (with integrate.sh output), human prompts, agent notifications, spawns."""
import json, os, re, sys, pickle, collections
from datetime import datetime
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parse_agents import tool_cat, strip_bg, result_text, ts

L = '/home/agent/.claude/projects/-c-Users-Gripe-personal-repositories-it-socks-to-be-a-washing-machine/08fda595-82ec-42d1-a22f-67d094c58b5b.jsonl'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lead.pkl')

def lead_cat(name, inp):
    if name == 'Agent': return 'spawn agent'
    if name == 'SendMessage': return 'message agent'
    if name == 'AskUserQuestion': return 'ask designer'
    if name in ('TaskStop', 'ListAgents', 'Monitor', 'ScheduleWakeup'): return 'agent control/wait'
    return strip_bg(tool_cat(name, inp))

def main():
    ev = []; msgs = {}; uses = {}; humans = []; notifs = []
    with open(L) as fh:
        for l in fh:
            if '"timestamp"' not in l: continue
            try: d = json.loads(l)
            except Exception: continue
            t = d.get('timestamp'); typ = d.get('type')
            if not t or typ not in ('assistant', 'user', 'attachment'): continue
            T = ts(t); m = d.get('message') or {}
            if typ == 'assistant':
                mid = m.get('id') or d.get('uuid')
                r = msgs.setdefault(mid, dict(tools=[], usage={}))
                u = m.get('usage') or {}
                if (u.get('output_tokens') or 0) >= (r['usage'].get('output_tokens') or 0): r['usage'] = u
                for b in m.get('content') or []:
                    if isinstance(b, dict) and b.get('type') == 'tool_use':
                        inp = b.get('input') or {}
                        r['tools'].append(b['id'])
                        uses[b['id']] = dict(t=T, name=b.get('name'), cat=lead_cat(b.get('name', ''), inp),
                                             bg=bool(inp.get('run_in_background')), end=None, out='',
                                             cmd=(inp.get('command') or inp.get('prompt') or inp.get('description') or '')[:400],
                                             desc=inp.get('description', ''), notif=None)
                ev.append((T, 'asst', mid))
            elif typ == 'user':
                c = m.get('content')
                if isinstance(c, str):
                    if '<task-notification>' in c: ev.append((T, 'notif', c[:800]))
                    elif not re.match(r'\s*(<command-|<local-command|Caveat:|This session is being continued|\[Request interrupted)', c):
                        ev.append((T, 'human', c[:300]))
                elif isinstance(c, list):
                    ids = []
                    for b in c:
                        if isinstance(b, dict) and b.get('type') == 'tool_result':
                            i = b.get('tool_use_id'); ids.append(i)
                            if i in uses and uses[i]['end'] is None:
                                uses[i]['end'] = T
                                txt = result_text(b)
                                keep = 6000 if uses[i]['cat'] in ('merge',) or 'integrate' in uses[i]['cmd'] else 400
                                uses[i]['out'] = txt[-keep:]
                                k = re.search(r'background with ID: (\w+)', txt)
                                if k: uses[i]['task'] = k.group(1)
                                k = re.search(r'agentId: (\w+)', txt)
                                if k: uses[i]['agent'] = k.group(1)
                        elif isinstance(b, dict) and b.get('type') == 'text':
                            tx = b.get('text', '')
                            if '<task-notification>' in tx: ev.append((T, 'notif', tx[:800]))
                            elif tx and not re.match(r'\s*(<command-|<local-command|Caveat:|<system-reminder>|\[Request interrupted)', tx):
                                ev.append((T, 'human', tx[:300]))
                    if ids: ev.append((T, 'result', ids))
            elif typ == 'attachment':
                a = d.get('attachment') or {}
                if a.get('type') == 'queued_command':
                    pr = str(a.get('prompt', ''))
                    if '<task-notification>' in pr: ev.append((T, 'notif', pr[:800]))
                    elif (a.get('origin') or {}).get('kind') == 'human': ev.append((T, 'human', pr[:300]))
    ev.sort(key=lambda e: e[0])
    # dedupe notifications / humans that appear twice (attachment + user line)
    seen = {}; ev2 = []
    for e in ev:
        if e[1] in ('notif', 'human'):
            key = (e[1], re.sub(r'\s+', ' ', e[2])[:200])
            if key in seen and e[0] - seen[key] < 3600: continue
            seen[key] = e[0]
        ev2.append(e)
    ev = ev2
    def msg_act(mid):
        r = msgs.get(mid)
        if not r or not r['tools']: return 'text to designer / turn end'
        cats = [uses[i]['cat'] for i in r['tools'] if i in uses]
        for c in cats:
            if c.startswith('edit:'): return c
        return cats[0]
    iv = collections.Counter(); waits = []; spans = []
    issued = set(); pending = set(); idle = False; prev = ev[0][0]; lastend = None
    for T, kind, pl in ev:
        dt = T - prev
        if kind == 'asst':
            iv[('gen', msg_act(pl))] += min(dt, 600); spans.append((prev, prev + min(dt, 600), 'gen', msg_act(pl)))
            r = msgs.get(pl)
            if r:
                for i in r['tools']:
                    if i in uses and i not in issued and uses[i]['end'] is not None and uses[i]['t'] <= T:
                        issued.add(i); pending.add(i)
                idle = not r['tools']
            prev = T
        elif kind == 'result':
            cat = None
            for i in pl:
                if i in uses: cat = cat or ('bg launch' if uses[i]['bg'] else uses[i]['cat'])
                pending.discard(i)
            iv[('tool', cat or 'other')] += min(dt, 3600); spans.append((prev, prev + min(dt, 3600), 'tool', cat or 'other'))
            idle = False; prev = T
        elif kind in ('notif', 'human'):
            if idle and not pending:
                if kind == 'human': w = 'designer'
                else:
                    w = 'agent finished' if re.search(r'<summary>Agent ', pl) else 'background command'
                waits.append((prev, T, w, pl[:200]))
                prev = T
            if kind == 'human': idle = False
    tokens = collections.defaultdict(collections.Counter)
    for mid, r in msgs.items():
        u = r['usage']; tk = tokens[msg_act(mid)]
        tk['out'] += u.get('output_tokens') or 0
        tk['in'] += (u.get('input_tokens') or 0) + (u.get('cache_read_input_tokens') or 0) + (u.get('cache_creation_input_tokens') or 0)
        tk['msgs'] += 1
    calls = sorted(({**u, 'id': i} for i, u in uses.items()), key=lambda c: c['t'])
    humans = [(T, pl) for T, k, pl in ev if k == 'human']
    notifs = [(T, pl) for T, k, pl in ev if k == 'notif']
    pickle.dump(dict(iv=dict(iv), spans=spans, waits=waits, calls=calls, humans=humans, notifs=notifs,
                     first=ev[0][0], last=ev[-1][0], tokens={k: dict(v) for k, v in tokens.items()},
                     times=[e[0] for e in ev]), open(OUT, 'wb'))
    print('lead: events', len(ev), 'calls', len(calls), 'humans', len(humans), 'notifs', len(notifs))

if __name__ == '__main__':
    main()
