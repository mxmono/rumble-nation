extends "res://cards/leader.gd"


func _ready() -> void:
	card_name = "Uesugi Kenshin"
	card_name_jp = "上杉謙信"
	description = "Move up to 3 of your soldiers from your leader territory to any number of adjacent territories by land."
	
	effect = []  # effect is updated on card selection
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
		2. leader territory has land connection
		3. player has at least 1 soldier on leader territory
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false
	
	var leader_territory = get_leader_territory(player, null)[0]
	
	if GameState.board_state["territory_connections"][leader_territory]["land"].size() == 0:
		return false
	
	if GameState.board_state["territory_tally"][leader_territory][player]["soldier"] <= 0:
		return false

	return true

func update_card_on_selection():
	
	super.update_card_on_selection()
	
	var current_player = GameState.current_player
	
	# update effects based on state when card is selected
	var soldiers_on_leader_territory = GameState.board_state["territory_tally"][self.leader_territory][current_player]["soldier"]
	self.effect = []
	for i in range(soldiers_on_leader_territory):
		self.effect.append(
			{"deploy": -1, "territory": "leader_initial_occupied", "player": "current", "territory_selection_required": true}
		)
		self.effect.append(
			{"deploy": 1, "territory": "leader_adjacent_land", "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		)
