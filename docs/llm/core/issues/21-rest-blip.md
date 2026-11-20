---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[13-two-tier-mess]]"]
notes: []
terms: []
---

# A Sock blips when it comes to rest

Found by the designer (2026-11-20): "when a thing is dropped and once it's frozen it blips and changes look". Reproduced by the
lead: `builds/review-core-21/before-rest-blip.png` (a lob at the handling station, every 4 frames, cropped): up to
frame 160 the flying Sock casts a shadow and is shaded; from 164, when it rests and becomes a MultiMesh instance of the
two-tier Mess, its shadow is gone and it looks lighter and flatter.

## Fault
F1 A Sock coming to rest (a drop, a throw, a wake) must look the same the frame before and after: colour, shading,
shadow, shape, place. Suspects to check one by one with an A/B shot each (do not fix by guess):
- the material: the Looks' per-colour `StandardMaterial3D` (`game/sock/sock_dress.gd:42`) against the Mess's shared
  vertex-colour material with per-instance colour (`game/mess/mess_drawing.gd:55`): the sRGB conversion of the instance
  colour, roughness, culling;
- the shadow: whether the MultiMesh instances cast shadows (and with what AABB) as the Looks' `crew` mesh does in its
  lying state;
- the shape: the flying Looks bends with the cloth (core/09) while the MultiMesh draws the rest pose; the cloth must be
  flat by the time it rests (D04), and the skinned mesh's rest pose must be the mesh the MultiMesh draws;
- the place: the record's pose against where the body lay (two-box collider offsets).
The same check for a Pair's ball coming to rest, and for the aimed Sock lending and giving back its Looks (M03).

## Acceptance
- A test that compares a resting Sock's drawn look before and after the switch (colour, shadow casting, transform), and
  a before and after strip in `builds/review-core-21/`; the ticket goes ready-for-human.

## Answers

## Open follow-ups

## Built log
- Model: Opus (lead): rendering debugging across the Looks and the MultiMesh.
