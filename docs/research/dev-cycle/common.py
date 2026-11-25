"""Shared loading: agent records, lead record, tickets, merges, activity groups."""
import os, re, glob, pickle, collections, statistics
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = '/c/Users/Gripe/personal/repositories/it-socks-to-be-a-washing-machine'

def load_agents(): return [r for r in pickle.load(open(os.path.join(HERE, 'agents.pkl'), 'rb')) if not r['prompt'].startswith('You are analysing where development time goes')]
def load_lead(): return pickle.load(open(os.path.join(HERE, 'lead.pkl'), 'rb'))

GROUP = [
    ('Write game GDScript', ('edit: game GDScript', 'edit: kit GDScript')),
    ('Write test GDScript', ('edit: test GDScript',)),
    ('Edit scene .tscn', ('edit: scene .tscn',)),
    ('Edit resource .tres', ('edit: resource .tres',)),
    ('Write docs/tickets .md', ('edit: docs/tickets .md',)),
    ('Write helper .sh/.py', ('edit: helper .sh/.py',)),
    ('Other edits (config, data)', ('edit: config/data', 'edit: other')),
    ('Read/explore code', ('read/explore',)),
    ('Tests: run.sh', ('test: run.sh',)),
    ('Tests: agent_finish', ('test: agent_finish',)),
    ('Tests: check.sh', ('test: check.sh',)),
    ('Tests: reading logs', ('read test output',)),
    ('Lint/kit checks', ('lint/kit checks',)),
    ('Godot ad hoc runs', ('godot ad hoc',)),
    ('Wait/poll loops, Monitor', ('wait/poll',)),
    ('Shots and viewing stills', ('shots',)),
    ('Blender', ('blender',)),
    ('Git and commits', ('git',)),
    ('Other shell', ('other shell',)),
    ('Report text / turn end', ('text: report / turn end',)),
]
def group_of(cat):
    for g, cats in GROUP:
        if cat in cats: return g
    if cat.startswith('meta'): return 'Tool search, skills, misc'
    return 'Other shell'
GROUP_NAMES = [g for g, _ in GROUP] + ['Tool search, skills, misc']
BIG = {  # coarse families for the headline
    'Write game GDScript': 'Writing code/scenes', 'Write test GDScript': 'Writing tests',
    'Edit scene .tscn': 'Writing code/scenes', 'Edit resource .tres': 'Writing code/scenes',
    'Write docs/tickets .md': 'Docs and tickets', 'Write helper .sh/.py': 'Helper scripts',
    'Other edits (config, data)': 'Writing code/scenes', 'Read/explore code': 'Reading/exploring',
    'Tests: run.sh': 'Testing', 'Tests: agent_finish': 'Testing', 'Tests: check.sh': 'Testing', 'Tests: reading logs': 'Testing',
    'Lint/kit checks': 'Testing', 'Godot ad hoc runs': 'Testing', 'Wait/poll loops, Monitor': 'Testing',
    'Shots and viewing stills': 'Shots/stills', 'Blender': 'Blender', 'Git and commits': 'Git/commits',
    'Other shell': 'Other', 'Report text / turn end': 'Reporting', 'Tool search, skills, misc': 'Other'}

def active(r):
    return sum(v for (s, a), v in r['intervals'].items() if s in ('gen', 'tool', 'wait-bg'))

# ---- tickets
def read_tickets():
    T = {}
    for f in glob.glob(REPO + '/docs/llm/*/issues/*.md'):
        rel = os.path.relpath(f, REPO)
        fm = {}; title = ''
        with open(f) as fh:
            txt = fh.read(6000)
        m = re.match(r'---\n(.*?)\n---', txt, re.S)
        if m:
            for ln in m.group(1).splitlines():
                k = re.match(r'(\w+):\s*(.*)', ln)
                if k: fm[k.group(1)] = k.group(2).strip()
        t = re.search(r'^# (.+)$', txt, re.M)
        title = t.group(1) if t else ''
        T[rel] = dict(kind=fm.get('kind', ''), area=fm.get('area', ''), status=fm.get('status', ''),
                      title=title, created=fm.get('created', ''), done=fm.get('done', ''), notes=fm.get('notes', ''))
    return T

def ticket_id(path):
    m = re.search(r'docs/llm/([^/]+)/issues/(\d+[a-z]?)', path or '')
    return '%s/%s' % (m.group(1), m.group(2).lstrip('0') or '0') if m else None

def ttype(meta, path, r_blender_share=0.0):
    k = (meta or {}).get('kind', ''); a = (meta or {}).get('area', ''); title = ((meta or {}).get('title', '') + ' ' + (path or '')).lower()
    if 'flaky' in title or 'flake' in title: return 'flaky fix'
    if a == 'assets' or k == 'content' or r_blender_share > 0.15: return 'asset/Blender'
    if k == 'bug': return 'bug'
    if k in ('design', 'research', 'docs'): return 'design/research'
    if k in ('refactor', 'maintenance', 'chore'): return 'refactor/maintenance'
    return 'feature'

def pct(xs, q):
    xs = sorted(xs)
    if not xs: return 0
    i = min(len(xs) - 1, int(round(q * (len(xs) - 1))))
    return xs[i]

def fmt_h(s): return '%.1f' % (s / 3600)
def utc(t): return datetime.utcfromtimestamp(t).strftime('%m-%d %H:%M')
