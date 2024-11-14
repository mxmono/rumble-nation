extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "TaiKyaku/ Retreat"
	card_name_jp = "退却"
	description = "Return 2 of your soldiers to hand from any number of territories."
	effect = [
		{"deploy": -1, "territory": "occupied_soldier", "player": "current", "territory_selection_required": true, "emit": true},
		{"deploy": -1, "territory": "occupied_soldier", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have at least one two soldiers on the board.
	"""
	
	if GameState.players[player]["soldier"] > GameState.total_soldiers - 2:
		return false
	
	return true
