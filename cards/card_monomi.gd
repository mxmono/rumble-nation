extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "Monomi"
	card_name_jp = "物見"
	description = "Move exactly one soldier to any adjacent territory."
	effect = [
		{"deploy": -1, "territory": "occupied", "player": "current"},
		{"deploy": 1, "territory": "adjacent", "player": "current"},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. Must have a piece on map.
	"""

	if Settings.players[player]["territories"].size() == 0:
		return false
	
	return true
