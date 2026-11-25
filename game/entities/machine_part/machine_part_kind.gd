## One of the washing machine's Parts as data (docs/architecture/stages.md "How it is authored"): the
## Part a Stage earns, by its id, the name the hover readout shows, and its Looks (empty until core/79
## and assets/12). One `.tres` per Part in this folder.
class_name MachinePartKind
extends Resource

## Its id on the wire and in a save.
@export var id := &""
## What the readout names it ("New filter"). placeholder: the old wording (T:parts)
@export var name := ""
## Its Looks scene (core/79); empty draws nothing.
@export var looks: PackedScene
