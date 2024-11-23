extends Leader


func _ready() -> void:
	card_name = "Ootomo Sourin"
	card_name_jp = "大友宗麟"
	description = "Bounce 1 opponent's soldier and replace it with 1 from your hand in a territory adjacent to your leader up to 2 times (can target different opponents)."
	
	# effect needs to be updated, based on how many opponent pieces are available on the board,
	# and on how many soldiers the player still has left
	effect = [
		{"deploy": -1, "player": "other", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": false, "finish_allowed": true, "emit": true},
		{"deploy": -1, "player": "other", "territory_selection_required": true},
		{"deploy": 1, "player": "current", "territory_selection_required": false, "finish_allowed": true, "emit": true},
	]
	
	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. on leader adjacent territories, there are other player soldiers
		3. techincally, playe needs soldier left, but is redundant because can't get here if played
			leader but have no soldier left (player is out)
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false
	
	if get_valid_targets(player).size() == 0:
		return false
	
	return true


func get_valid_targets(player: int) -> Array:
	"""Players who have soldiers on current player leader adjacent territory."""
	
	# this is only called on first click, so okay to get leader occupied dynamically
	var leader_adjacent_territories = TerritoryHelper.get_adjacent_by_connection_type(
		TerritoryHelper.get_player_leader_occupied(player), "all"
	)
	var valid_targets = []
	for opponent in TerritoryHelper.get_opponents(player):
		var opponent_territories = TerritoryHelper.get_player_soldier_occupied(opponent)
		if Helper.get_array_overlap(leader_adjacent_territories, opponent_territories).size() > 0:
			valid_targets.append(opponent)
	
	return valid_targets


func get_valid_targets_on_territory(player: int, territory_index: int) -> Array:
	# override parent function, as the territory must have soldiers (not any piece)
	
	var target_pool = get_valid_targets(player)

	var valid_targets = []
	for target in target_pool:
		if GameState.board_state["territory_tally"][territory_index][target]["soldier"] > 0:
			valid_targets.append(target)
	
	return valid_targets


func update_card_on_selection():
	"""Update how many steps are allowed based on opponent piece and hand piece."""
	
	super.update_card_on_selection()
	
	var current_player = GameState.current_player
	var valid_targets = get_valid_targets(current_player)
	var leader_adjacent_territories = TerritoryHelper.get_adjacent_by_connection_type(
		self.leader_territory, "all"
	)
	
	# if all of valid targets only have 1 soldier in total, remove 2nd bounce
	var valid_soldiers = 0
	for territory in leader_adjacent_territories:
		var territory_tally = GameState.board_state["territory_tally"][territory]
		for opponent in TerritoryHelper.get_opponents(current_player):
			valid_soldiers += territory_tally[opponent]["soldier"]
	
	if valid_soldiers == 1:
		self.effect = self.effect.slice(0, 2)
	
	# if only 1 piece left in hand, also can only take 1 step
	if GameState.players[current_player]["soldier"] == 1:
		self.effect = self.effect.slice(0, 2)


func update_effect(player):
	"""Given player can choose different opponents, reset opponent after 1 step."""
	if self.effect_index == 1:  # called before the increment before staged moves
		self.selected_opponent = -1


func get_card_step_territories(step: int) -> Array:
	# step 1: adjacent to player leader + opponent soldier occupied
	if step == 0:
		var leader_adjacents = TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "all")
		var opponent_soldier_occupied = []
		
		# if opponent is known
		if self.selected_opponent != -1:
			opponent_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(self.selected_opponent)
			
		# otherwise get all opponents' soldier occupied
		else:
			opponent_soldier_occupied = TerritoryHelper.get_players_soldier_occupied(
				TerritoryHelper.get_opponents(GameState.current_player)
			)
		
		return Helper.get_array_overlap(leader_adjacents, opponent_soldier_occupied)
	
	# step 2: same as step 1 (replce move)
	if step == 1:
		return [self.staged_moves[0][1]]
	
	# step 3: same criteria as step 1, but step 1 territory is no longer valid
	if step == 2:
		var leader_adjacents = TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "all")
		var opponent_soldier_occupied = TerritoryHelper.get_player_soldier_occupied(self.selected_opponent)
		var territories = Helper.get_array_overlap(leader_adjacents, opponent_soldier_occupied)
		territories.erase(self.staged_moves[0][1])
		return territories
	
	# step 4: same as step 3:
	if step == 3:
		return [self.staged_moves[2][1]]
	
	return []
