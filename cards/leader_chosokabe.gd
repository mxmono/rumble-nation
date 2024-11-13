extends "res://cards/leader.gd"


func _ready() -> void:
	card_name = "Chosokabe Motochika"
	card_name_jp = "長宗我部元親"
	description = "Move up to 3 pieces (leader or soldier) from your leader territory to any number of adjacent territories by water."
	effect = []
	for i in range(3):
		effect.append({"deploy": -1, "territory": "leader_initial_occupied", "player": "current", "territory_selection_required": true})
		effect.append({"deploy": 1, "territory": "leader_adjacent_water", "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true})
	
	# leader is optional here
	is_leader_optional_or_undecided = true

	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. player leader territory has water connection
	"""
	
	if Settings.players[player]["leader"] >= 1:
		return false
	
	var leader_territory = get_leader_territory(player)[0]
	if Settings.board_state["territory_connections"][leader_territory]["water"].size() == 0:
		return false

	return true

func reset_card():
	super.reset_card()
	self.is_leader_optional_or_undecided = true

func update_effect(player):
	# can only move up to number of total pieces on leader territory
	# below updates each early emit
	var times_allowed = Settings.board_state["territory_tally"][self.leader_territory][player]["soldier"]
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
		
		self.effect.append({"deploy": -1, "territory": "leader_initial_occupied", "player": "current", "territory_selection_required": true, "has_leader": has_leader})
		self.effect.append({"deploy": 1, "territory": "leader_adjacent_water", "player": "current", "territory_selection_required": true, "has_leader": has_leader, "finish_allowed": true, "emit": true})
