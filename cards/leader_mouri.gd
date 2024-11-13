extends "res://cards/leader.gd"


func _ready() -> void:
	card_name = "Mouri Motonari"
	card_name_jp = "毛利元就"
	description = "Deploy 1 of your soldiers from hand to a territory adjacent to the territory your leader occupies up to 3 times."
	# effect is updated on selection
	effect = [
		{"deploy": 1, "territory": "leader_adjacent", "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		{"deploy": 1, "territory": "leader_adjacent_not_already_selected", "player": "current", "territory_selection_required": true, "finish_allowed": true, "emit": true},
		{"deploy": 1, "territory": "leader_adjacent_not_already_selected", "player": "current", "territory_selection_required": true},
	]
	
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player has played the leader
	"""
	
	if Settings.players[player]["leader"] >= 1:
		return false

	return true

func update_card_on_selection():
	super.update_card_on_selection()
	
	var current_player = get_node("/root/GameController").current_player
	# can only click up to the times the player has soldier left
	var soldiers_left = Settings.players[current_player]["soldier"]
	
	if soldiers_left <= self.effect.size():
		self.effect = self.effect.slice(0, soldiers_left)
