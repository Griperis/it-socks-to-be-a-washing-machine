## One of the two currencies (docs/architecture/economy.md "How it is authored", Q2610): its name, its
## icon and the colour of its flying "+N". `coins.tres` (each player's own) and `drawers.tres` (the
## team's) beside this file; the designer renames or swaps an icon here with no code change.
class_name Currency
extends Resource

## The name the game says ("Coins", "Drawers"), as in "Debug: +1000 Coins".
@export var name := ""
## Its counter's and its flying icons' picture.
@export var icon: Texture2D
## The colour of its "+N" text (white; the House blue for the Drawers).
@export var tint := Color.WHITE
