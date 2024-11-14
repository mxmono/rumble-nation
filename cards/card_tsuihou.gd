extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "TsuiHou / Expel"
	card_name_jp = "追放"
	description = "Move 1 opponent's soldier from a territory you occupy to an adjacent territory."
	effect = [
		{"deploy": -1, "territory": "occupied_both_soldiers", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "adjacent_selected", "player": "other", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have pieces on board
		2. there must be other players on territories the player occupies
	"""
	
	if GameState.players[player]["territories"].size() == 0:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true

func get_valid_targets(player):
	"""Opponent must occupy the same territory."""
	
	var player_territories = GameState.players[player]["territories"]
	var territory_tallies = GameState.board_state["territory_tally"]
	var valid_targets = []
	
	for opponent in range(GameState.players.size()):
		if opponent == player:
			continue
		
		var opponent_territories = GameState.players[opponent]["territories"]
		for opponent_territory in opponent_territories:
			if player_territories.has(opponent_territory):
				if territory_tallies[opponent_territory][opponent]["soldier"] > 0:
					valid_targets.append(opponent)
					break
	
	return valid_targets
