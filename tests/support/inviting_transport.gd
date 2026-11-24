## A test transport that can invite (the stand-in for Steam's, core/67): ENet's wire, and it counts the invites.
class_name InvitingTransport
extends EnetTransport

## How many times the Lobby's "Invite friends" key asked it.
var invited := 0


func can_invite() -> bool:
	return true


func invite() -> void:
	invited += 1
