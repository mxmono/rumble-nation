extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "SuiGun / Navy"
	card_name_jp = "水軍"
	description = "Move 2 of your soldiers from one territory to an adjacent territory by water."
	effect = [
		{"deploy": -2, "territory": "_suigun", "player": "current", "territory_selection_required": true},
		{"deploy": 2, "territory": "adjacent_selected_water", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have at least 2 soldiers on a territory with water connection.
	"""
	
	if super.get_suigun_territories(player, null).size() == 0:
		return false
	
	return true
