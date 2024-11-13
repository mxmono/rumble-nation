extends "res://cards/leader.gd"


func _ready() -> void:
	card_name = "Takeda Shingen"
	card_name_jp = "武田信玄"
	description = "Expel up to 3 of one opponent's soldiers from your leader territory to any number of adjancent territories."
	
	# effect needs to be updated, based on which opponent the current player selectes
	effect = [
		{"deploy": -1, "territory": "leader_initial_occupied", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "leader_adjacent", "player": "other", "territory_selection_required": true, "finish_allowed": true, "emit": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. on leader territory, there are at least 1 other player's soldiers
	"""
	
	if Settings.players[player]["leader"] >= 1:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true

func get_valid_targets(player):
	"""Players who have soldiers on current player leader territory."""
	
	var leader_territory = get_leader_territory(player, null)[0]
	var territory_tally = Settings.board_state["territory_tally"][leader_territory]
	
	var valid_targets = []
	for opponent in range(territory_tally.size()):
		if opponent == player:
			continue
		if territory_tally[opponent]["soldier"] > 0:
			valid_targets.append(opponent)
	
	return valid_targets

func update_effect(player):
	"""Depending on which opponent is selected, update number of applicable effects."""
	if self.selected_opponent == -1:
		return
	
	# get how many soldiers are on player leader territory, below updates on early emit
	var num_opponent_soldiers = Settings.board_state["territory_tally"][self.leader_territory][self.selected_opponent]["soldier"]
	var soldiers_already_moved = self.staged_moves.size() / 2
	var effect_times = min(3, num_opponent_soldiers + soldiers_already_moved)
	
	# update effect
	self.effect = []
	for i in range(effect_times):
		self.effect += [
			{"deploy": -1, "territory": "leader_initial_occupied", "player": "other", "territory_selection_required": true},
			{"deploy": 1, "territory": "leader_adjacent", "player": "other", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		]
