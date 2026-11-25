## One World total of the Final screen (Q1835): a caption, which number a provider answers (`source`) and how
## it is written. Batch A has Play time, Coins earned and Stages; batch B adds a total by adding a
## FinalTotal to final_totals.tres, with no change to the screen.
class_name FinalTotal
extends Resource

enum Format { COUNT, TIME }

## What the total is called under the line.
@export var caption := ""
## The name FinalSummary.values answers it under ("play_time", "coins_earned", "stages").
@export var source: StringName = &""
## A count, or seconds written h:mm:ss.
@export var format := Format.COUNT


## `value` as the screen writes it.
func text_of(value: int) -> String:
	if format == Format.TIME:
		return "%d:%02d:%02d" % [value / 3600, (value / 60) % 60, value % 60]
	return str(value)
