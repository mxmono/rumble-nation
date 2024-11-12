extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "MuHon / Coup"
	card_name_jp = "謀反"
	description = "Return one opponent's soldier to hand and replace it with one soldier from your hand."
	effect = [
		{"deploy": -1, "territory": "occupied_other", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "previous_selected", "player": "current", "territory_selection_required": false},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have soldiers left
		2. there must be other player pieces on the board
	"""
	
	if Settings.players[player]["soldier"] <= 0:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true

func get_valid_targets(player) -> Array:
	"""All players with pieces (except self) are valid."""
	
	var valid_targets = []
	
	for p in range(Settings.players.size()):
		if p == player:
			continue
		
		if Settings.players[p]["territories"].size() > 0:
			valid_targets.append(p)
	
	return valid_targets
