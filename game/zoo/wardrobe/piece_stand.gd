## One stand of the Wardrobe station (core/128): an AvatarLooks wearing one piece, labelled with its name,
## Collection and Rarity; a Trail steps its sample beside it.
class_name PieceStand
extends Node3D

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare"]

## The piece it shows (show_piece()).
var piece: WardrobePiece = null


## Wears `p` and names it.
func show_piece(p: WardrobePiece) -> void:
	piece = p
	name = "Stand_%s" % p.id
	var looks := $Looks as AvatarLooks
	if p.slot == WardrobePiece.Slot.TRAIL:
		looks.dresser().demo = true
	var look := WardrobeLook.empty()
	look[WardrobeLook.key(p.slot)] = p.id
	looks.look = look
	var c := Collections.of(p.collection) if p.collection != &"" else null
	($Label as Label3D).text = "%s\n%s · %s" % [Wardrobe.piece_name(p.id), c.name if c != null else "Basic", RARITY_NAMES[p.rarity]]
