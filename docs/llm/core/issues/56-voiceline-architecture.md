---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: voice
priority: next
created: 2026-11-23
done:
blocked_by: []
notes: ["Q2535: designed first, before the washer, the Old Tree and the cutscenes (M5)"]
terms: []
---

# The architecture and authoring of voicelines

Before the talking washing machine, the Old Tree and the cutscenes are ported (M5), design how voicelines are made,
stored, triggered, heard and subtitled (Q2535). A design ticket: no game code; the output is a proposal and questions
for the designer.

## Step 1: findings
Read the old system by examination (grep; never commit in reference/): `reference/it-socks/data/voice*`,
`tools/voiceover/`, the washer's and the Old Tree's voice code, cutscenes 1-6, subtitles, "heard only when audible",
music ducking, voice ageing (the Old Tree). Write `docs/migration/voice-findings.md`: every line kind, how it was
authored (scripts, transcripts, takes, picks), triggered, played (3D, priority, interrupting, queueing), subtitled and
localised; what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/voice.md` (proposal): a typed Resource per line or per speaker set (text, takes, the speaker, the
trigger, priority, the subtitle), how a designer adds or swaps a line by dropping a file and naming it (as the sound
system, Q2296), how it fits the plug-and-play sound system (core/17), co-op (who hears what, the Host's trigger),
subtitles on the one Theme, localisation later (`kit/docs/agents/shipping-basics.md`), and a tiny zoo station sketch.
End with the choices for the designer, 2-3 options each with a recommendation.
