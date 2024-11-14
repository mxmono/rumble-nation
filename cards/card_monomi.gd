extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "MonoMi / Sightseeing"
	card_name_jp = "物見"
	description = "Move 1 of your soldiers to any adjacent territory."
	effect = [
		{"deploy": -1, "territory": "occupied_soldier", "player": "current", "territory_selection_required": true},
		{"deploy": 1, "territory": "adjacent", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. Must have a soldier on map.
	"""

	if TerritoryHelper.get_player_territories_soldiers_only(player).size() == 0:
		return false
	
	return true
