---
type: ticket
status: done
kind: design
area: core
feature: voice
priority: next
created: 2026-11-23
done: 2026-11-23
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

## Open follow-ups
- [blocking] V1-V8 in `docs/architecture/voice.md` "Choices for the designer": who decides the Old Tree's lines in
  co-op; Animation vs code-sampled acting; takes; two speakers at once; Voice bus and ducking; subtitle look; where a
  line's text is first written; a muffled line's subtitle. Each has 2-3 options and a recommendation.

## Built log
### 2026-11-23
- Changed: Step 1 and Step 2 written (docs only). Findings: every line kind of the old game (washer comments,
  cutscenes, drum comments, Old Tree lines and calls), how each was authored, triggered, played, subtitled, and what
  was weak. Proposal: VoiceLine/VoiceSegment/VoiceSpeaker Resources, a VoiceBook built at load, one VoicePicker, a
  Voices autoload, a Subtitles scene on the Theme, drop-a-file authoring through a bake tool, a Voice bus, the Host
  deciding lines in co-op, subtitle keys in a CSV from the start, a Voice zoo station sketch; choices V1-V8.
- Files: docs/migration/voice-findings.md, docs/architecture/voice.md
- Verified: docs only, no suite (agent_finish --no-test).

## Answers
- V1-V8 answered by Q2545-Q2552 (designer, 2026-11-23): the Host decides every speaker; a baked Animation per line;
  several takes picked at random; priority cutscene > washer > Old Tree, lower dropped except waiting story beats; a
  Voice bus with its slider, music ducking only in cutscenes; the old subtitle look with the speaker's icon, no name;
  text transcribed from the recording, corrected in the string table; subtitles shown within earshot through Doors.
  `docs/architecture/voice.md` is the agreed design; the build tickets come with the washer and the Old Tree (M5).
