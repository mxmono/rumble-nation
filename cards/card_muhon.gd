extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "MuHon / Coup"
	card_name_jp = "謀反"
	description = "Bounce 1 opponent's soldier and replace it with 1 soldier from your hand."
	effect = [
		{"deploy": -1, "territory": "occupied_other_soldiers_only", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "previous_selected", "player": "current", "territory_selection_required": false},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have soldiers left
		2. there must be other player soldiers on the board
	"""
	
	if GameState.players[player]["soldier"] <= 0:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true

func get_valid_targets(player) -> Array:
	"""All players with soldiers (except self) are valid."""
	
	var valid_targets = []
	
	for opponent in range(GameState.players.size()):
		if opponent == player:
			continue
		
		if TerritoryHelper.get_player_territories_soldiers_only(opponent).size() > 0:
			valid_targets.append(opponent)
	
	return valid_targets
