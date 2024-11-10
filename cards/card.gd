extends Button

signal card_selected(card)

@export var card_name: String = "Base Card"
@export var card_name_jp: String = "卡片"
@export var description: String = "Description of the card"
@export var selection_required: int = 0
var effect = []  # an array of dictionaries of moves
var effect_index = 0  # which step is effect at, 0 = initial, 1 = after 1st step
var staged_moves = []  # staged moves associated with usage of the card, [player, territory_index, deploy_count, has_leader]
var territory_func_mapping = {
	"occupied": get_occupied_territories,
	"adjacent": get_adjacent_territories,
	"occupied_both": get_occupied_both_territories,  # both self and other players occupy
	"occupied_other": get_occupied_other_territories,
	"occupied_other_adjacent_to_self": get_other_player_adjacent_territories,
	"adjacent_occupied": get_adjacent_occupied_territories,
	"adjacent_selected": get_adjacent_territories_to_selected,
	"_otori": get_otori_territories,
	"_jouraku": get_jouraku_territories,
	"_suigun": get_suigun_territories,
	"adjacent_selected_water": get_adjacent_selected_water,
}
var selected_opponent: int = -1 # to which opponent is the card targeting
var last_selected_territory = -1

func _ready() -> void:
	$ENTitle.text = card_name
	$JPTitle.text = card_name_jp
	$Description.text = description
	
	self.pressed.connect(_on_card_selected)
	
func update_valid_targets():
	# draw eligible opponents in TargetHBox if condition met
	var current_player = get_node("/root/GameController").current_player
	
	# clear existing children
	for node in $TargetHBox.get_children():
		$TargetHBox.remove_child(node)
		node.queue_free()
		
	# target selection, only needed when more than 2 players
	if Settings.num_players > 2:
		if is_condition_met(current_player):
			var valid_targets = get_valid_targets(current_player)
			if valid_targets.size() > 0:
				# if there are valid targets, add those buttons
				for target in valid_targets:
					var target_icon = Settings.players[target]["icon"]
					var target_button = Button.new()
					target_button.icon = target_icon
					target_button.text = Settings.players[target]["name"]
					$TargetHBox.add_child(target_button)
					# if overflowing, shrink button size
					var max_x = $Description.get_rect().size.x
					if target_button.get_rect().size.x * valid_targets.size() >= max_x:
						target_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
						target_button.custom_minimum_size.x = (max_x - 10) / valid_targets.size()

func _on_card_selected():
	if Settings.num_players == 2:
		self.selected_opponent = 1 - get_node("/root/GameController").current_player
	
	card_selected.emit(self)

func is_condition_met(player) -> bool:
	return false

func get_valid_targets(player) -> Array:
	return []

func get_occupied_territories(player, territroy_index=null) -> Array:
	"""Returns an array territory index."""
	return Settings.players[player]["territories"]

func get_occupied_other_territories(player, territroy_index) -> Array:
	# the `other player` is the selected opponent of the card itself, not passed through arg
	var territories = []
	
	# if one player is selected
	if self.selected_opponent != -1:
		territories = get_occupied_territories(self.selected_opponent)
	
	# otherwise, show all players'
	else:
		for p in range(Settings.players.size()):
			if p == player:
				continue
			var opponent_territories = Settings.players[p]["territories"]
			for t in opponent_territories:
				if not territories.has(t):
					territories.append(t)
	
	return territories

func get_occupied_both_territories(player, territory_index=null) -> Array:
	"""Get territories occupied both by self and other players."""
	
	var player_territories = Settings.players[player]["territories"]
	var valid_territories = []
	
	# get opponents, if not selected, return all other players
	var opponents = []
	if self.selected_opponent != -1:
		opponents = [self.selected_opponent]
	else:
		for opponent in range(Settings.players.size()):
			if opponent == player:
				continue
			opponents.append(opponent)
	
	# for each opponent, find territories player and opponent both occupy
	for opponent in opponents:
		var opponent_territories = Settings.players[opponent]["territories"]
		for opponent_territory in opponent_territories:
			if player_territories.has(opponent_territory):
				if not valid_territories.has(opponent_territory):
					valid_territories.append(opponent_territory)
	
	return valid_territories

func get_adjacent_territories(player, territory_index) -> Array:
	# error handling
	if territory_index == null:
		return []

	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var current_connections = territory_connections[territory_index]
	
	# get select territory's adjacent territorries
	return current_connections["all"]

func get_adjacent_territories_to_selected(player, territory_index) -> Array:
	return get_adjacent_territories(player, self.last_selected_territory)

func get_adjacent_occupied_territories(player, territory_index) -> Array:
	"""Get other_player's adjacent territories occupied by player given a territory_index."""
	# it's the reverse of get_other_player_adjacent_territories
	return _get_other_player_adjacent_territories(self.selected_opponent, territory_index, player)

func get_other_player_adjacent_territories(player, territory_index) -> Array:
	return _get_other_player_adjacent_territories(player, territory_index, self.selected_opponent)

func _get_other_player_adjacent_territories(player, territory_index, other_player) -> Array:
	"""Find territories `other_player` occupies that are adjacent to `player` `territory`."""
	# get variables
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var player_territories = Settings.players[player]["territories"]
	var other_player_territories = []
	if other_player != -1:  # ie opponent has been selected
		other_player_territories = Settings.players[other_player]["territories"]
	else:  # ie opponent has not been selected, show all opponent's territories
		for i in range(Settings.players.size()):
			if i == player:  # skip self
				continue
			for t in Settings.players[i]["territories"]:
				if not other_player_territories.has(t):
					other_player_territories.append(t)
	
	# if territory_index is given, only look for adjacent to given territory
	# otherwise, search all territories the player has
	var player_territories_to_loop_through = player_territories
	if territory_index != null:
		player_territories_to_loop_through = [territory_index]
		
	var valid_territories = []
	for territory in player_territories_to_loop_through:
		var connected_territories = get_adjacent_territories(player, territory)
		for connected_territory in connected_territories:
			if connected_territory in other_player_territories:
				if not valid_territories.has(connected_territory):
					valid_territories.append(connected_territory)
	
	return valid_territories

func get_otori_territories(player, territory_index):
	"""Territoies with one of self and at least two of others."""
	
	var player_territories = Settings.players[player]["territories"]
	var board_state = get_node("/root/GameController/Map").board_state
	var valid_territories = []
	
	for territory in player_territories:
		for opponent in range(Settings.players.size()):
			if opponent == player:
				continue
			if board_state[territory][opponent]["soldier"] >= 2:
				if not valid_territories.has(territory):
					valid_territories.append(territory)
	
	return valid_territories

func get_jouraku_territories(player, territory_index):
	"""Territories around kyo (4) the player occupies."""
	
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var valid_territory_pool = territory_connections[4]["all"]
	var valid_territories = []
	
	for player_territory in Settings.players[player]["territories"]:
		if valid_territory_pool.has(player_territory):
			valid_territories.append(player_territory)
			
	return valid_territories

func get_suigun_territories(player, territory_index=null):
	"""Get territories player has >=2 soldiers that has water connections."""
	
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var board_state = get_node("/root/GameController/Map").board_state
	var player_territories = Settings.players[player]["territories"]
	var valid_territory_pool = []
	var valid_territories = []
	
	for territory in range(territory_connections.size()):
		if territory_connections[territory]["water"].size() > 0:
			valid_territory_pool.append(territory)

	for player_territory in player_territories:
		if valid_territory_pool.has(player_territory):
			if board_state[player_territory][player]["soldier"] >= 2:
				valid_territories.append(player_territory)

	return valid_territories

func get_adjacent_selected_water(player, territory_index=null):
	"""Get territories adjacent to selected territory by water."""

	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var current_connections = territory_connections[self.last_selected_territory]
	
	# get select territory's adjacent territorries
	return current_connections["water"]
