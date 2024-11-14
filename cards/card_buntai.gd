extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "BunTai / Squad Split"
	card_name_jp = "分隊"
	description = "Move half (round down) of your soldiers from one territory to any one adjacent territory."
	
	effect = [
		{"deploy": -1, "territory": "_buntai", "player": "current", "territory_selection_required": true},
		{"deploy": 1, "territory": "adjacent_selected", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have >=2 soldiers on any territory.
	"""
	
	if super.get_buntai_territories(player, null).size() > 0:
		return true
	
	return false

func update_effect(player):

	# half of the player's soldiers on selected territory
	var board_state =GameState.board_state["territory_tally"]
	var deploy_count = 0
	if self.staged_moves.size() > 0:  # ie step 2, the first move is alredy staged
		deploy_count = board_state[self.staged_moves[0][1]][player]["soldier"] / 2
	else:  # step 1, use last clicked territory
		deploy_count = board_state[self.last_selected_territory][player]["soldier"] / 2
	
	# update the effect
	self.effect[0]["deploy"] = -deploy_count
	self.effect[1]["deploy"] = deploy_count
