extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "Kasei/Reinforcement"
	card_name_jp = "加勢"
	description = "Deploy one soldier from hand to any territory you occupy."
	effect = [
		{"deploy": 1, "territory": "occupied", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have soldiers left
		2. there must be territories with existing pieces from the player
	"""
	
	if Settings.players[player]["soldier"] <= 0:
		return false
	
	if Settings.players[player]["territories"].size() == 0:
		return false
	
	return true
