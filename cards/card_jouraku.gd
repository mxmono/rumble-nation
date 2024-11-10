extends "res://cards/card.gd"


func _ready() -> void:
	card_name = "JouRaku / Capital March"
	card_name_jp = "上洛"
	description = "Deploy any number of your own soldiers from any number of territories adjacent to Kyo to Kyo."
	
	# special to this card: max number of times is total number of pieces in adjacent territories.
	var current_player = get_node("/root/GameController").current_player
	var max_deploy_times = get_max_deploy_times(current_player)
	# TODO:
	for i in range(max_deploy_times):
		effect.append(
			{"deploy": -1, "territory": "_jouraku", "player": "current", "territory_selection_required": true},
		)
		effect.append(
			{"deploy": 1, "territory": "_kyo", "player": "current", "territory_selection_required": false},
		)
		
	super._ready()

func is_condition_met(player):
	"""Conditions:
		1. player must have territories adjacent to kyo (index = 4)
	"""
	
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var valid_territories = territory_connections[4]["all"]
	
	for player_territory in Settings.players[player]["territories"]:
		if valid_territories.has(player_territory):
			return true
	
	return false

func get_max_deploy_times(player) -> int:
	
	var valid_territories = super.get_jouraku_territories(player, null)
	var board_state = get_node("/root/GameController/Map").board_state
	var max_deploy_times = 0
	
	for territory in valid_territories:
		max_deploy_times += board_state[territory][player]["soldier"]
	
	return max_deploy_times
