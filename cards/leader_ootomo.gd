extends "res://cards/leader.gd"


func _ready() -> void:
	card_name = "Ootomo Sourin"
	card_name_jp = "大友宗麟"
	description = "Bounce 1 opponent's soldier and replace it with 1 from your hand in a territory adjacent to your leader up to 2 times (can target different opponents)."
	
	# effect needs to be updated, based on how many opponent pieces are available on the board,
	# and on how many soldiers the player still has left
	effect = [
		{"deploy": -1, "territory": "leader_adjacent_opponent_occupied", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "previous_selected", "player": "current", "territory_selection_required": false, "finish_allowed": true, "emit": true},
		{"deploy": -1, "territory": "_ootomo_step_2", "player": "other", "territory_selection_required": true},
		{"deploy": 1, "territory": "previous_selected", "player": "current", "territory_selection_required": false, "finish_allowed": true, "emit": true},
	]
	
	territory_func_mapping.merge({"_ootomo_step_2": get_ootomo_step_2_territories})
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. on leader adjacent territories, there are other player soldiers
		3. techincally, playe needs soldier left, but is redundant because can't get here if played
			leader but have no soldier left (player is out)
	"""
	
	if Settings.players[player]["leader"] >= 1:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true

func get_valid_targets(player):
	"""Players who have soldiers on current player leader adjacent territory."""
	
	var leader_adjacent_territories = get_leader_adjacent_territories(player, null)

	var valid_targets = []
	for territory in leader_adjacent_territories:
		var territory_tally = Settings.board_state["territory_tally"][territory]
		for opponent in range(territory_tally.size()):
			if opponent == player:
				continue
			if territory_tally[opponent]["soldier"] > 0:
				if not valid_targets.has(opponent):
					valid_targets.append(opponent)
	
	return valid_targets

func get_valid_targets_on_territory(player, territory_index) -> Array:
	# override parent function, as the territory must have soldiers (not any piece)
	
	var target_pool = get_valid_targets(player)
	print("target pool: ", target_pool)
	var valid_targets = []
	for target in target_pool:
		if Settings.board_state["territory_tally"][territory_index][target]["soldier"] > 0:
			valid_targets.append(target)
	
	return valid_targets

func update_card_on_selection():
	"""Update how many steps are allowed based on opponent piece and hand piece."""
	
	super.update_card_on_selection()
	
	var current_player = get_node("/root/GameController").current_player
	var valid_targets = get_valid_targets(current_player)
	var leader_adjacent_territories = get_leader_adjacent_territories(current_player, null)
	
	# if valid targets only have 1 soldier in total, remove 2nd step
	var valid_soldiers = 0
	for territory in leader_adjacent_territories:
		var territory_tally = Settings.board_state["territory_tally"][territory]
		for opponent in range(territory_tally.size()):
			if opponent == current_player:
				continue
			valid_soldiers += territory_tally[opponent]["soldier"]
	
	if valid_soldiers == 1:
		self.effect = self.effect.slice(0, 2)
	
	# if only 1 piece left in hand, also can only take 1 step
	if Settings.players[current_player]["soldier"] == 1:
		self.effect = self.effect.slice(0, 2)

func update_effect(player):
	"""Given player can choose different opponents, reset opponent after 1 step."""
	if self.effect_index == 1:  # called before the increment before staged moves
		self.selected_opponent = -1

func get_ootomo_step_2_territories(player, territory_index):
	"""Can't be the same as previous step."""
	
	var valid_territories = get_leader_adjacent_territories_occupied_by_any_opponent(player, null)
	var selected_territory = self.staged_moves[0][1]
	
	valid_territories.erase(selected_territory)
	
	return valid_territories
