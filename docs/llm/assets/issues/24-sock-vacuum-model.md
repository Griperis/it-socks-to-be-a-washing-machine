---
type: ticket
status: ready-for-human
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 1", "suggested model: opus"]
terms: [Sock vacuum, Nozzle display]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The Sock vacuum's model

The old Sock vacuum (`make_sock_vacuum.py`; the nozzle's pod from `assets/vacuum_devices/make_nozzle_display.py`)
ported by the asset port rules, the old colours: the mint canister of the retro appliance family, the capsule window
with its heap markers, the gauge slot, the parking clip (`Hook`), the nozzle with its mouth, the pod with its
SubViewport face, and the hose's cream ribbed tube with chrome cuffs re-made as a skinned tube with bones for core/168's
rope. Its Looks meets the contract `docs/architecture/devices.md` "Looks contracts" names (`Body`, `Hook`,
`NozzleMouth`, `HoseTop`, `Window` heap markers, `Gauge`, `Pod`, `Streaks`, `Motes`, `Motor`; clips `pour`, `settle`,
`fill`, `motor_on`, `motor_off`; the hose's `tug`). Draft AS-C2-1.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/sock_vacuum/` and its `assets/blender_assets.json` entry; the shared
materials (Q2177); the clips keyed in the Looks.

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-sock-vacuum/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `sock_vacuum.tscn` points its Looks (and the hose's mesh) at these; the graybox goes.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).

## Open follow-ups
