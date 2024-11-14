extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "KaSei / Reinforcement"
	card_name_jp = "加勢"
	description = "Deploy 1 soldier from your hand to any territory your soldiers occupy."
	effect = [
		{"deploy": 1, "territory": "occupied_soldier", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have soldiers left
		2. there must be territories with existing soldiers from the player
	"""
	
	if GameState.players[player]["soldier"] <= 0:
		return false
	
	if TerritoryHelper.get_player_territories_soldiers_only(player).size() == 0:
		return false
	
	return true
