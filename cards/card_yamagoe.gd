extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "YamaGoE / Moutain Cross"
	card_name_jp = "山越え"
	description = "Move 2 of your soldiers from one territory to an adjacent territory by land."
	effect = [
		{"deploy": -2, "territory": "_yamagoe", "player": "current", "territory_selection_required": true},
		{"deploy": 2, "territory": "adjacent_selected_land", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have at least 2 soldiers on a territory with land connection.
	"""
	
	if super.get_yamagoe_territories(player, null).size() == 0:
		return false
	
	return true
