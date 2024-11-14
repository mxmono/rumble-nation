extends "res://cards/leader.gd"


func _ready() -> void:
	card_name = "Oda Nobunaga"
	card_name_jp = "織田信長"
	description = "Move your leader to an adjacent territory. You can move up to 1 soldier with your leader."
	
	effect = [
		# leader move
		{"deploy": -1, "territory": "leader_initial_occupied", "player": "current", "territory_selection_required": true, "has_leader": true},
		{"deploy": 1, "territory": "leader_adjacent", "player": "current", "territory_selection_required": true, "has_leader": true, "finish_allowed": true, "emit": true},
		# optional soldier move
		{"deploy": -1, "territory": "leader_initial_occupied", "player": "current", "territory_selection_required": true},
		{"deploy": 1, "territory": "_oda_soldier", "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
	]
	
	territory_func_mapping.merge(
		{"_oda_soldier": get_oda_soldier_territories}
	)
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
	"""
	
	if GameState.players[player]["leader"] >= 1:
		return false
	
	return true

func update_card_on_selection():
	"""If no soldier on leader territory, remove the optional step."""
	
	super.update_card_on_selection()
		
	var current_player = GameState.current_player
	var leader_territory = get_leader_territory(current_player, null)[0]
	var soldiers_on_leader_territory = GameState.board_state["territory_tally"][leader_territory][current_player]["soldier"]

	# if no soldier on leader territory, remove the optional step
	if soldiers_on_leader_territory <= 0:
		self.effect = self.effect.slice(0, 2)

func get_oda_soldier_territories(player, territory_index=null):
	"""Return the territory selected in step 2 (the one leader moved to)."""
	
	# first index: move 2; second index: territory_index in move array
	return [self.staged_moves[1][1]]
