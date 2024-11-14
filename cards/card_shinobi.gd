extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "Shinobi / Ninja"
	card_name_jp = "忍"
	description = "Move 1 of your soldiers from any territory to any other territory your soldiers occupy."
	effect = [
		{"deploy": -1, "territory": "occupied_soldier", "player": "current", "territory_selection_required": true},
		{"deploy": 1, "territory": "occupied_not_previous_selected_soldier", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have at least two territories with soldiers.
	"""
	
	if TerritoryHelper.get_player_territories_soldiers_only(player).size() >= 2:
		return true
	
	return false
