extends Leader


func _ready() -> void:
	card_name = "Chosokabe M"
	card_name_jp = "長宗我部元親"
	description = "Move up to 3 pieces (leader or soldier) from your leader territory to any number of adjacent territories by water."
	effect = []
	for i in range(3):
		effect.append({"deploy": -1, "player": "current", "territory_selection_required": true})
		effect.append({"deploy": 1, "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true})
	
	# leader is optional here
	is_leader_optional_or_undecided = true

	super._ready()


func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. player leader territory has water connection
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false
	
	var leader_territory = TerritoryHelper.get_player_leader_occupied(player)
	if GameState.board_state["territory_connections"][leader_territory]["water"].size() == 0:
		return false

	return true


func reset_card():
	super.reset_card()
	self.is_leader_optional_or_undecided = true


func update_effect(player):
	# can only move up to number of total pieces on leader territory
	# below updates each early emit
	var times_allowed = TerritoryHelper.get_player_territory_tally(player, self.leader_territory)["soldier"]
	
	if self.apply_to_leader:
		if effect_index <= 1:
			times_allowed += 1  # only plus 1 if leader hasn't been played (ie effect step 0 and 1)
	
	# as territory tally updates when emits early, it's remaining soldiers + already played moves
	var total_times = min(3, times_allowed + self.staged_moves.size() / 2)
	self.effect = []
	
	for i in range(total_times):
		var has_leader = false
		if self.apply_to_leader:
			if i == 0:
				has_leader = true
		
		self.effect += [
			{"deploy": -1, "player": "current", "territory_selection_required": true, "has_leader": has_leader},
			{"deploy": 1, "player": "current", "territory_selection_required": true, "has_leader": has_leader, "finish_allowed": true, "emit": true},
		]


func get_card_step_territories(step: int) -> Array:
	# step 1: leader initial occupied territory
	if step % 2 == 0:
		return [self.leader_territory]
	
	# step 2: water-connected territories adjacent to leader
	if step % 2 == 1:
		return TerritoryHelper.get_adjacent_by_connection_type(self.leader_territory, "water")
	
	return []
