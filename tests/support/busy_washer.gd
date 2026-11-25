## A stand-in washing machine for the tests (core/79): in the group the slot asks, busy while `busy_now`.
extends Node

var busy_now := true


func busy() -> bool:
	return busy_now
