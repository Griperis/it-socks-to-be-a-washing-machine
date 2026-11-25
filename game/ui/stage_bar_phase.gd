## The Stage bar's text in one phase of the run (Q2621; docs/architecture/stages.md "How it is
## authored"): a later phase plugs in with a Resource and no bar change. Its two numbers come from
## the provider named `source`: a node in the group `stage_bar_source` whose `bar_source()` is that
## name and whose `bar_numbers()` gives them (Stages answers `stage_rows`).
class_name StageBarPhase
extends Resource

## The bar's icons: none, the bar's Cabinets' Collections, or the one `icon`.
enum Icons { NONE, CABINETS, GIVEN }

## The group of the nodes that give a phase its numbers.
const SOURCES := &"stage_bar_source"

## The label, a format string ("Stage %d: %s  %d/%d"). placeholder: the old wording (HUD:397)
@export var text := ""
## The provider of its numbers; empty for none.
@export var source := &""
## Whether it shows the track.
@export var track := true
@export var icons := Icons.NONE
## The UiIcons key shown when `icons` is GIVEN.
@export var icon := ""
