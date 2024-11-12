extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "Shinobi / Ninja"
	card_name_jp = "忍"
	description = "Move one of your soldiers from any territory to any other territory you occupy."
	effect = [
		{"deploy": -1, "territory": "occupied", "player": "current", "territory_selection_required": true},
		{"deploy": 1, "territory": "occupied", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have at least two territories.
	"""
	
	if Settings.players[player]["territories"].size() >= 2:
		return true
	
	return false
