---
type: home
---

# It Socks: work in progress

Open this folder (`docs/llm/`) as an Obsidian vault. **[[Progress.base]]** is the dashboard. Its
views are **Board** (everything open, by status), **Needs you** (decisions and triage waiting on
you), **In progress**, **Done** (newest first) and **By area**.

## How it works

- One folder per feature or effort. Each folder holds its `spec.md` and one note per ticket in
  `issues/`.
- A new ticket starts from `_templates/ticket.md` (Templates plugin: "Insert template").
- A ticket's **frontmatter** carries its status. Agents set it to `in-progress` when they start
  and `done` when they finish.
- Each ticket's **Built log** is the agent's record: what changed, which files, how it was
  verified, and (added at merge) the merge hash.
- **Open follow-ups** are questions an agent ran into and left for you to answer.
- `kind: decision` tickets are questions for you. They're answered in a grilling session, and the
  answers spawn `build` tickets.
- The conventions are in `kit/docs/agents/issue-tracker.md` (outside this vault).

## Features

- [[mvp/spec|MVP]]: the first playable build.
- `questions/`: the open design questions, one `decision` ticket per area.
- `maintenance/`: tooling, docs drift and cleanups.
