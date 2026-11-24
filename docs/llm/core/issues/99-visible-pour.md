---
type: ticket
status: needs-info
kind: build
area: core
feature: laundry
priority: later
created: 2026-11-24
done:
blocked_by: [core/93]
notes: ["after batch A (Q2627)", "suggested model: sonnet"]
terms: [Laundry bin, Laundry day]
---

# The visible pour of a Laundry bin

Look work after batch A's review (Q2627, Q2153: a look change is its own ticket): loading a bin today is the old
tip, whoosh and pile; the Socks are never seen going in and the tip barely shows in first person (Q1907, `docs/migration/m4-lists/04-first-wash-and-laundry-day.md` "What was
weak"). This ticket makes the pour visible: a short stream of Socks from the bin into the door and a tip seen in first
person. Not batch A.

## How it is authored

Its numbers in `LaundryTuning` (a "Pour" group), placeholders; a strip in the Laundry station.

## Acceptance
- Stops at its first strip for the designer's go (look work); no test (Q2421).
- No rule change: `LaundryDay.load` is untouched.

## Answers
- Loading stays as the old in batch A; a visible pour is a later polish ticket (Q2627, 2026-11-24).

## Open follow-ups
- [blocking] The pour's look (designer-grilling rule 10): what moves (how many Socks, from where in the bin, how fast), where the tip sits in first person, what the player sees up close. Asked after batch A's review.

## Built log
