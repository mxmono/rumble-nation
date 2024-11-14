extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "Otori / Decoy"
	card_name_jp = "囮"
	description = "Move 1 of your soldiers and 2 of an opponent's soldiers to any adjancent territory."
	effect = [
		{"deploy": -2, "territory": "_otori", "player": "other", "territory_selection_required": true},  # the first one needs to be "other" player
		{"deploy": -1, "territory": "previous_selected", "player": "current", "territory_selection_required": false},
		{"deploy": 2, "territory": "adjacent_selected", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "previous_selected", "player": "current", "territory_selection_required": false},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. there must be territories with one of self and two of the same others
	"""
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true

func get_valid_targets(player):
	
	var player_territories = TerritoryHelper.get_player_territories_soldiers_only(player)
	var valid_targets = []
	
	for territory in player_territories:
		for opponent in range(GameState.players.size()):
			if opponent == player:
				continue
			if TerritoryHelper.get_player_territory_tally(opponent, territory)["soldier"] >= 2:
				if not valid_targets.has(opponent):
					valid_targets.append(opponent)
	
	return valid_targets
