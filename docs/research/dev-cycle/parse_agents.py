#!/usr/bin/env python3
"""Parse every subagent transcript into a compact record (pickle): active-time intervals by
state and activity, tokens by activity, every test run with its duration, verdict and selection,
and every edit. Usage: parse_agents.py [SINCE=2026-11-20] -> agents.pkl next to this script."""
import json, os, re, sys, glob, pickle, collections
from datetime import datetime

P = '/home/agent/.claude/projects/-c-Users-Gripe-personal-repositories-it-socks-to-be-a-washing-machine/08fda595-82ec-42d1-a22f-67d094c58b5b/subagents'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'agents.pkl')
SINCE = sys.argv[1] if len(sys.argv) > 1 else '2026-11-20'
GEN_CAP = 600      # a model turn longer than 10 min is a stall, not generation
TOOL_CAP = 3600    # a foreground tool call longer than 60 min is a suspended call
WAIT_CAP = 3600    # waiting for a background run's notification

def ts(s): return datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp()

EXT_GROUP = {'.gd': 'gd', '.gdshader': 'gd', '.tscn': 'tscn', '.tres': 'tres', '.md': 'md',
             '.sh': 'helper', '.py': 'helper', '.json': 'data', '.txt': 'data', '.cfg': 'data',
             '.godot': 'data', '.import': 'data', '.uid': 'data', '.csv': 'data', '.yml': 'data'}

def path_cat(p):
    p = p or ''
    ext = os.path.splitext(p)[1].lower()
    g = EXT_GROUP.get(ext, 'other')
    if g == 'gd':
        if re.search(r'(^|/)tests/', p) and not re.search(r'/kit/', p): return 'edit: test GDScript'
        if re.search(r'(^|/)kit/', p): return 'edit: kit GDScript'
        return 'edit: game GDScript'
    if g == 'tscn': return 'edit: scene .tscn'
    if g == 'tres': return 'edit: resource .tres'
    if g == 'md': return 'edit: docs/tickets .md'
    if g == 'helper':
        if 'tools/blender/' in p: return 'blender'
        return 'edit: helper .sh/.py'
    if g == 'data': return 'edit: config/data'
    return 'edit: other'

WRITE_TARGETS = [
    r"open\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"][wa]",      # python open(path,'w')
    r"Path\(\s*['\"]([^'\"]+)['\"]\s*\)\.write_text",
    r"cat\s+>{1,2}\s*([^\s<;&|]+)\s*<<",                   # cat > f <<EOF
    r"cat\s+<<-?\s*['\"]?\w+['\"]?\s*>{1,2}\s*([^\s;&|]+)",# cat <<EOF > f
    r"\btee\s+(?:-a\s+)?([^\s;&|]+)",
    r"sed\s+-i[^ ]*\s+(?:-e\s+)?(?:'[^']*'|\"[^\"]*\"|\S+)\s+([^\s;&|]+)",
    r"perl\s+-[a-z]*i[a-z]*\s+(?:-e\s+)?(?:'[^']*'|\S+)\s+([^\s;&|]+)",
]

HEREDOC = re.compile(r"<<-?\s*['\"]?(\w+)['\"]?[^\n]*\n.*?\n\s*\1\s*(\n|$)", re.S)
def segments(c):
    body = HEREDOC.sub('\n', c)
    segs = re.split(r'\n|;|&&|\|\||\||\(|\)|\bdo\b|\bthen\b', body)
    res = []
    for sg in segs:
        sg = sg.strip()
        sg = re.sub(r'^((\w+=\S*|timeout( -\w+)* \d+\w?|env|nice|time|bash|sh|exec|xvfb-run( -\S+)*)\s+)+', '', sg)
        if sg: res.append(sg)
    return res
def invoked(c, pat):
    return any(re.match(r'(\S*/)?' + pat, sg) for sg in segments(c))

def bash_cat(c):
    if invoked(c, r'agent_finish\.sh'): return 'test: agent_finish'
    if invoked(c, r'run\.(sh|py)\b') and not re.search(r'run\.sh\s+(--help|--list|--ledger)', c): return 'test: run.sh'
    if invoked(c, r'check\.sh'): return 'test: check.sh'
    if invoked(c, r'(shot\.sh|shot_set\.sh|net_shot\.sh|png_strip\.py|baseline\.py|tour\.sh)') or re.search(r'python3?\s+\S*(png_strip|baseline)\.py', c): return 'shots'
    if re.search(r'blender', c, re.I): return 'blender'
    if re.search(r'integrate\.sh', c): return 'merge'
    if re.search(r'\bsleep\b|while .*(pgrep|kill -0)|until .*;|tail -[fF]|inotifywait', c): return 'wait/poll'
    for r in WRITE_TARGETS:
        m = re.search(r, c)
        if m and not m.group(1).startswith('/dev/') and not re.search(r'\.(log|out)$', m.group(1)) and '/tmp/' not in m.group(1):
            return path_cat(m.group(1))
    if re.search(r'commit\.sh|git_repair|git_check|agent_start\.sh|^\s*(cd [^;&]*&&\s*)?git\b|\bgit (add|commit|diff|log|status|show|rev-parse|merge|rebase|stash|checkout|hash-object|ls-files|cat-file|branch)', c): return 'git'
    if re.search(r'engine\.sh|Godot_v|\$GODOT|\bgodot\b', c): return 'godot ad hoc'
    if re.search(r'grep_rules|asset_lint|uid_check|input_actions|scene_links|placeholders\.py', c): return 'lint/kit checks'
    if re.search(r'\.log\b|/tasks/\w+\.output|PASS\|FAIL|FAIL\|PASS|ledger', c) and re.search(r'\b(grep|cat|head|tail|sed|awk|wc)\b', c): return 'read test output'
    if re.search(r'\b(grep|rg|find|ls|cat|head|tail|sed -n|wc|diff|awk|tree|stat|file)\b', c): return 'read/explore'
    if re.search(r'python3?\b', c): return 'other shell'
    return 'other shell'

def tool_cat(name, inp):
    if name == 'Bash':
        return bash_cat(inp.get('command', '')) if not inp.get('run_in_background') else 'BG ' + bash_cat(inp.get('command', ''))
    if name in ('Write', 'Edit', 'MultiEdit', 'NotebookEdit'):
        return path_cat(inp.get('file_path') or inp.get('notebook_path'))
    if name == 'Read':
        p = inp.get('file_path', '')
        if re.search(r'\.(png|jpe?g|webp|gif)$', p, re.I): return 'shots'
        if re.search(r'\.(log|output)$', p): return 'read test output'
        return 'read/explore'
    if name in ('Grep', 'Glob', 'LS'): return 'read/explore'
    if name.startswith('mcp__blender'): return 'blender'
    if name in ('Monitor',): return 'wait/poll'
    return 'meta: ' + name

def strip_bg(c): return c[3:] if c.startswith('BG ') else c

def result_text(b):
    x = b.get('content')
    if isinstance(x, str): return x
    if isinstance(x, list): return '\n'.join(y.get('text', '') for y in x if isinstance(y, dict) and y.get('type') == 'text')
    return ''

VERDICT = re.compile(r'^(PASS \d+ checks, \d+ cases.*|FAIL \d+ of \d+ checks, \d+ cases.*|TIMED OUT.*|FAIL import.*)$', re.M)

def parse(path):
    meta = {}
    mp = path[:-6] + '.meta.json'
    if os.path.exists(mp):
        try: meta = json.load(open(mp))
        except Exception: pass
    ev = []          # (t, kind, payload)
    msgs = {}        # id -> dict(first,last,tools[],usage,vis)
    uses = {}        # tool_use id -> dict
    prompt = None
    taskmap = {}
    def note(T, txt):
        tid = re.search(r'<tool-use-id>(\S+?)</tool-use-id>', txt)
        st = re.search(r'<status>(\w+)</status>', txt)
        ec = re.search(r'exit code (\d+)', txt)
        i = tid.group(1) if tid else None
        if i is None:
            k = re.search(r'<task-id>(\w+)</task-id>', txt)
            i = taskmap.get(k.group(1)) if k else None
            if i is None: i = 'MONITOR' if 'Monitor event' in txt else None
        ev.append((T, 'notif', i))
        if i in uses and uses[i]['notif'] is None:
            uses[i]['notif'] = T
            uses[i]['notif_status'] = (st.group(1) if st else '') + (' ' + ec.group(1) if ec else '')
    with open(path) as fh:
        for l in fh:
            try: d = json.loads(l)
            except Exception: continue
            t = d.get('timestamp')
            typ = d.get('type')
            if not t: continue
            if t[:10] < SINCE: continue
            T = ts(t)
            m = d.get('message') or {}
            if typ == 'assistant':
                mid = m.get('id') or d.get('uuid')
                r = msgs.setdefault(mid, dict(first=T, last=T, tools=[], usage={}, vis=0, model=m.get('model')))
                r['last'] = max(r['last'], T)
                u = m.get('usage') or {}
                if (u.get('output_tokens') or 0) >= (r['usage'].get('output_tokens') or 0): r['usage'] = u
                for b in m.get('content') or []:
                    if not isinstance(b, dict): continue
                    if b.get('type') == 'tool_use':
                        inp = b.get('input') or {}
                        cat = tool_cat(b.get('name', ''), inp)
                        r['tools'].append(b['id'])
                        r['vis'] += len(json.dumps(inp))
                        uses[b['id']] = dict(t=T, name=b.get('name'), cat=cat, mid=mid,
                                             cmd=HEREDOC.sub('\n', inp.get('command') or '')[:700] if b.get('name') == 'Bash' else '',
                                             writes=bool(re.search(r"open\([^)]*['\"][wa]|sed -i|cat\s+>|write_text|perl -pi|\btee\b|git (checkout|restore|apply)", inp.get('command') or '')) if b.get('name') == 'Bash' else b.get('name') in ('Write', 'Edit', 'MultiEdit'),
                                             path=inp.get('file_path') or '', bg=bool(inp.get('run_in_background')),
                                             end=None, out=None, notif=None)
                    elif b.get('type') == 'text':
                        r['vis'] += len(b.get('text', ''))
                ev.append((T, 'asst', mid))
            elif typ == 'user':
                c = m.get('content')
                if isinstance(c, str):
                    if '<task-notification>' in c:
                        note(T, c)
                    elif c.startswith('[Image'):
                        pass
                    else:
                        if prompt is None: prompt = c
                        ev.append((T, 'prompt', c[:300]))
                elif isinstance(c, list):
                    ids = []
                    for b in c:
                        if isinstance(b, dict) and b.get('type') == 'tool_result':
                            i = b.get('tool_use_id'); ids.append(i)
                            if i in uses and uses[i]['end'] is None:
                                uses[i]['end'] = T
                                txt = result_text(b)
                                k = re.search(r'(?:background with ID|[Tt]ask[ _-]?[Ii][Dd])[:= ]+\W?(\w{6,})', txt)
                                if k: taskmap[k.group(1)] = i
                                uses[i]['out'] = txt[-4000:] if uses[i]['cat'].startswith(('test', 'BG test')) else txt[-300:]
                                uses[i]['err'] = bool(b.get('is_error'))
                        elif isinstance(b, dict) and b.get('type') == 'text' and '<task-notification>' in b.get('text', ''):
                            note(T, b['text'])
                    if ids: ev.append((T, 'result', ids))
                    elif prompt is None:
                        txt = ' '.join(b.get('text', '') for b in c if isinstance(b, dict) and b.get('type') == 'text')
                        if txt: prompt = txt; ev.append((T, 'prompt', txt[:300]))
            elif typ == 'attachment':
                a = d.get('attachment') or {}
                if a.get('type') == 'queued_command':
                    pr = str(a.get('prompt', ''))
                    if '<task-notification>' in pr:
                        note(T, pr)
                    else:
                        ev.append((T, 'prompt', pr[:300]))
    if not ev: return None
    ev.sort(key=lambda e: e[0])
    # message activity
    def msg_act(mid):
        r = msgs.get(mid)
        if not r or not r['tools']: return 'text: report / turn end'
        cats = [strip_bg(uses[i]['cat']) for i in r['tools'] if i in uses]
        # an edit among parallel calls wins: that is what the model was writing
        for c in cats:
            if c.startswith('edit:'): return c
        return cats[0] if cats else 'text: report / turn end'
    intervals = collections.Counter()   # (state, activity) -> seconds
    spans = []                           # (t0, t1, state) for concurrency
    pending = set()                      # foreground tool ids pending
    bg_pending = {}                      # bg tool id -> cat
    idle = False
    mgen = collections.Counter(); issued = set(); unk = []; react = collections.Counter(); lastcat = 'prompt'
    prev = ev[0][0]
    excess = 0.0
    DBG = os.environ.get('DBG')
    for (T, kind, pl) in ev:
        dt = T - prev
        if DBG and DBG.split(',')[0] <= datetime.utcfromtimestamp(T).isoformat() <= DBG.split(',')[1]:
            print(datetime.utcfromtimestamp(T).isoformat()[11:19], kind, str(pl)[:40], 'idle', idle, 'pend', len(pending))
        if kind == 'asst':
            act = msg_act(pl)
            d = min(dt, GEN_CAP); excess += dt - d
            intervals[('gen', act)] += d; spans.append((prev, prev + d, 'gen'))
            react[(lastcat, act)] += d
            mgen[pl] += d
            r = msgs.get(pl)
            # newly issued tools
            if r:
                for i in r['tools']:
                    if i in uses and i not in issued and uses[i]['end'] is not None and uses[i]['t'] <= T:
                        issued.add(i)
                        if uses[i]['bg']: bg_pending[i] = strip_bg(uses[i]['cat'])
                        pending.add(i)
                idle = not r['tools']
            prev = T
        elif kind == 'result':
            cat = None
            for i in pl:
                if i in uses:
                    c0 = 'meta: bg launch' if uses[i]['bg'] else strip_bg(uses[i]['cat'])
                    cat = cat or c0
                pending.discard(i)
            cat = cat or 'meta: other'
            lastcat = cat
            for i in pl:
                if i in uses and uses[i]['cat'].lstrip('BG ').startswith('test') and not uses[i]['bg']:
                    o = uses[i]['out'] or ''
                    if re.search(r'^FAIL|SCRIPT ERROR|TIMED OUT', o, re.M): lastcat = 'test FAILED'
            d = min(dt, TOOL_CAP); excess += dt - d
            intervals[('tool', cat)] += d; spans.append((prev, prev + d, 'tool'))
            idle = False
            prev = T
        elif kind == 'notif':
            if pl in bg_pending:
                c = bg_pending.pop(pl)
            elif pl == 'MONITOR' or (pl in uses and uses[pl]['name'] == 'Monitor'):
                c = 'wait/poll'
            elif pl in uses:
                c = strip_bg(uses[pl]['cat'])
            else:
                c = 'unknown'
            if idle and not pending:
                d = min(dt, WAIT_CAP); excess += dt - d
                intervals[('wait-bg', c)] += d; spans.append((prev, prev + d, 'wait'))
                lastcat = 'notification: ' + c
                if c == 'unknown': unk.append((prev, d, pl))
                prev = T
            # else: notification arrived while the agent was busy: not a boundary
        elif kind == 'prompt':
            if (idle and not pending) or dt > GEN_CAP:
                pending.clear()
                intervals[('idle', 'between turns (waiting for lead)')] += dt
                prev = T
            elif T == ev[0][0]:
                prev = T
            # a message injected while the agent works is not a boundary
            idle = False
            lastcat = 'prompt'
    # tokens by activity
    tokens = collections.defaultdict(lambda: collections.Counter())
    for mid, r in msgs.items():
        act = msg_act(mid)
        u = r['usage']
        tk = tokens[act]
        tk['out'] += u.get('output_tokens') or 0
        tk['in'] += u.get('input_tokens') or 0
        tk['cache_read'] += u.get('cache_read_input_tokens') or 0
        tk['cache_write'] += u.get('cache_creation_input_tokens') or 0
        tk['vis_chars'] += r['vis']
        tk['msgs'] += 1
    # tool calls list (compact)
    calls = []
    for i, u in uses.items():
        calls.append(dict(id=i, t=u['t'], end=u['end'], notif=u['notif'], cat=strip_bg(u['cat']), bg=u['bg'],
                          name=u['name'], cmd=u['cmd'], writes=u.get('writes'), path=u['path'], out=u['out'] or '', err=u.get('err'),
                          nstat=u.get('notif_status')))
    calls.sort(key=lambda c: c['t'])
    # results text after each call, for bg verdict lookup
    tm = re.search(r'Ticket:\s*(\S+\.md)', prompt or '')
    br = re.search(r'Branch:\s*(\S+?)\.?\s', prompt or '')
    return dict(id=os.path.basename(path)[6:-6], meta=meta, prompt=(prompt or '')[:600],
                ticket=tm.group(1) if tm else None, branch=br.group(1) if br else None,
                first=ev[0][0], last=ev[-1][0], intervals=dict(intervals), spans=spans,
                unk=unk, react=dict(react),
                msgstats=[(mgen[m], (msgs[m]['usage'].get('output_tokens') or 0), (msgs[m]['usage'].get('cache_read_input_tokens') or 0) + (msgs[m]['usage'].get('cache_creation_input_tokens') or 0) + (msgs[m]['usage'].get('input_tokens') or 0), msg_act(m), msgs[m]['last']) for m in msgs], tokens={k: dict(v) for k, v in tokens.items()}, calls=calls, excess=excess,
                prompts=[(T, pl) for T, k, pl in ev if k == 'prompt'],
                model=collections.Counter(r['model'] for r in msgs.values()).most_common(1)[0][0] if msgs else None)

def main():
    recs = []
    files = sorted(glob.glob(P + '/agent-*.jsonl'))
    for f in files:
        r = parse(f)
        if r: recs.append(r)
    pickle.dump(recs, open(OUT, 'wb'))
    print('parsed', len(recs), 'agent runs of', len(files), '->', OUT)

if __name__ == '__main__':
    main()
