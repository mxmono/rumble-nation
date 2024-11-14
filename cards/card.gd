class_name Card

extends Button

signal card_selected(card)

@export var card_type: String = "normal"
@export var card_name: String = "Base Card"
@export var card_name_jp: String = "卡片"
@export var description: String = "Description of the card"
@export var selection_required: int = 0
@export var early_finish_enabled: bool = false
var effect = []  # an array of dictionaries of moves
var effect_index = 0  # which step is effect at, 0 = initial, 1 = after 1st step
var staged_moves = []  # staged moves associated with usage of the card, [player, territory_index, deploy_count, has_leader]
var territory_func_mapping = {
	"occupied": get_occupied_territories,
	"occupied_soldier": get_occupied_territories_soldiers_only,
	"adjacent": get_adjacent_territories,
	"occupied_both": get_occupied_both_territories,  # both self and other players occupy
	"occupied_both_soldiers": get_occupied_both_territories_soldiers_only,
	"occupied_not_previous_selected": get_occupied_territories_not_previously_selected,
	"occupied_not_previous_selected_soldier": get_occupied_territories_not_previously_selected_soldiers_only,
	"occupied_other": get_occupied_other_territories,
	"occupied_other_soldiers_only": get_occupied_other_territories_soldiers_only,
	"occupied_other_adjacent_to_self": get_other_player_adjacent_territories,
	"occupied_other_soldiers_only_adjacent_to_self": get_other_player_soldiers_only_adjacent_territories,
	"adjacent_occupied": get_adjacent_occupied_territories,
	"adjacent_selected": get_adjacent_territories_to_selected,
	"_otori": get_otori_territories,
	"_jouraku": get_jouraku_territories,
	"_kyo": get_kyo,
	"_suigun": get_suigun_territories,
	"adjacent_selected_water": get_adjacent_selected_water,
	"_yamagoe": get_yamagoe_territories,
	"adjacent_selected_land": get_adjacent_selected_land,
	"_buntai": get_buntai_territories,
}
var selected_opponent: int = -1 # to which opponent is the card targeting
var last_selected_territory = -1

func _ready() -> void:
	$ENTitle.text = card_name
	$JPTitle.text = card_name_jp
	$Description.text = description
	
	self.pressed.connect(_on_card_selected)

func _process(delta):
	# gray out texts if disabled
	if self.disabled:
		$Mask.show()
	else:
		$Mask.hide()

func reset_card():
	self.staged_moves = []
	self.effect_index = 0
	self.selected_opponent = -1
	self.last_selected_territory = -1

func _on_card_selected():
	if GameState.num_players == 2:
		self.selected_opponent = 1 - GameState.current_player
	
	update_card_on_selection()
	
	card_selected.emit(self)

func is_condition_met(player) -> bool:
	return false

func get_valid_targets(player) -> Array:
	return []

func get_valid_targets_on_territory(player, territory_index) -> Array:
	"""Overlap of valid targets on clicked territory."""
	
	var target_pool = get_valid_targets(player)
	var valid_targets = []
	for target in target_pool:
		if GameState.players[target]["territories"].has(territory_index):
			valid_targets.append(target)
	
	return valid_targets

func update_effect(player):
	pass

func update_card_on_selection():
	pass

func get_occupied_territories(player, territroy_index=null) -> Array:
	"""Returns an array territory index."""
	return GameState.players[player]["territories"]

func get_occupied_territories_soldiers_only(player, territroy_index=null) -> Array:
	return TerritoryHelper.get_player_territories_soldiers_only(player)

func get_occupied_other_territories(player, territroy_index) -> Array:
	# the `other player` is the selected opponent of the card itself, not passed through arg
	var territories = []
	
	# if one player is selected
	if self.selected_opponent != -1:
		territories = get_occupied_territories(self.selected_opponent)
	
	# otherwise, show all players'
	else:
		for opponent in range(GameState.players.size()):
			if opponent == player:
				continue
			var opponent_territories = TerritoryHelper.get_player_territories(opponent)
			for t in opponent_territories:
				if not territories.has(t):
					territories.append(t)
	
	return territories

func get_occupied_other_territories_soldiers_only(player, territroy_index=null) -> Array:
	var territories = []
	
	# if one player is selected
	if self.selected_opponent != -1:
		territories = TerritoryHelper.get_player_territories_soldiers_only(self.selected_opponent)
	
	# otherwise, show all players'
	else:
		for opponent in range(GameState.players.size()):
			if opponent == player:
				continue
			var opponent_territories = TerritoryHelper.get_player_territories_soldiers_only(opponent)
			for t in opponent_territories:
				if not territories.has(t):
					territories.append(t)
	
	return territories

func get_occupied_both_territories(player, territory_index=null) -> Array:
	"""Get territories occupied both by self and other players."""
	
	var player_territories = GameState.players[player]["territories"]
	var valid_territories = []
	
	# get opponents, if not selected, return all other players
	var opponents = []
	if self.selected_opponent != -1:
		opponents = [self.selected_opponent]
	else:
		for opponent in range(GameState.players.size()):
			if opponent == player:
				continue
			opponents.append(opponent)
	
	# for each opponent, find territories player and opponent both occupy
	for opponent in opponents:
		var opponent_territories = GameState.players[opponent]["territories"]
		for opponent_territory in opponent_territories:
			if player_territories.has(opponent_territory):
				if not valid_territories.has(opponent_territory):
					valid_territories.append(opponent_territory)
	
	return valid_territories

func get_occupied_both_territories_soldiers_only(player, territory_index=null) -> Array:
	"""Occupied by self (leader or soldier), but must be occupied by other's soldiers."""
	
	var player_territories = GameState.players[player]["territories"]
	var valid_territories = []
	var territory_tallies = GameState.board_state["territory_tally"]
	
	# get opponents, if not selected, return all other players
	var opponents = []
	if self.selected_opponent != -1:
		opponents = [self.selected_opponent]
	else:
		for opponent in range(GameState.players.size()):
			if opponent == player:
				continue
			opponents.append(opponent)
	
	# for each opponent, find territories player and opponent both occupy
	for opponent in opponents:
		var opponent_territories = GameState.players[opponent]["territories"]
		for opponent_territory in opponent_territories:
			if player_territories.has(opponent_territory):
				if territory_tallies[opponent_territory][opponent]["soldier"] > 0:
					if not valid_territories.has(opponent_territory):
						valid_territories.append(opponent_territory)
	
	return valid_territories

func get_occupied_territories_not_previously_selected(player, territory_index) -> Array:
	
	var occupied_territories = get_occupied_territories(player)
	occupied_territories.erase(self.last_selected_territory)
	
	return occupied_territories

func get_occupied_territories_not_previously_selected_soldiers_only(player, territory_index) -> Array:
	var occupied_territories = TerritoryHelper.get_player_territories_soldiers_only(player)
	occupied_territories.erase(self.last_selected_territory)
	
	return occupied_territories
	

func get_adjacent_territories(player, territory_index) -> Array:
	# error handling
	if territory_index == null:
		return []

	var territory_connections = GameState.board_state["territory_connections"]
	var current_connections = territory_connections[territory_index]
	
	# get select territory's adjacent territorries
	return current_connections["all"]

func get_adjacent_territories_to_selected(player, territory_index) -> Array:
	return get_adjacent_territories(player, self.last_selected_territory)

func get_adjacent_occupied_territories(player, territory_index) -> Array:
	"""Get other_player's adjacent territories occupied by player given a territory_index."""
	# it's the reverse of get_other_player_adjacent_territories
	return _get_other_player_adjacent_territories(self.selected_opponent, territory_index, player, false)

func get_other_player_adjacent_territories(player, territory_index) -> Array:
	return _get_other_player_adjacent_territories(player, territory_index, self.selected_opponent, false)

func get_other_player_soldiers_only_adjacent_territories(player, territory_index) -> Array:
	return _get_other_player_adjacent_territories(player, territory_index, self.selected_opponent, true)

func _get_other_player_adjacent_territories(player, territory_index, other_player, soldiers_only) -> Array:
	"""Find territories `other_player` occupies that are adjacent to `player` `territory`."""
	# get variables
	var territory_connections = GameState.board_state["territory_connections"]
	var player_territories = GameState.players[player]["territories"]
	var other_player_territories = []
	if other_player != -1:  # ie opponent has been selected'
		if not soldiers_only:
			other_player_territories = TerritoryHelper.get_player_territories(other_player)
		else:
			other_player_territories = TerritoryHelper.get_player_territories_soldiers_only(other_player)
			
	else:  # ie opponent has not been selected, show all opponent's territories
		for opponent in range(GameState.players.size()):
			if opponent == player:  # skip self
				continue
			var opponent_territories = []
			if soldiers_only:
				opponent_territories = TerritoryHelper.get_player_territories_soldiers_only(opponent)
			else:
				opponent_territories = TerritoryHelper.get_player_territories(opponent)
			for t in opponent_territories:
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
	"""Territoies with one of self and at least two of others. Soldiers only."""
	
	var player_territories = TerritoryHelper.get_player_territories_soldiers_only(player)
	var valid_territories = []
	
	for territory in player_territories:
		for opponent in range(GameState.players.size()):
			if opponent == player:
				continue
			if TerritoryHelper.get_player_territory_tally(opponent, territory)["soldier"] >= 2:
				if not valid_territories.has(territory):
					valid_territories.append(territory)
	
	return valid_territories

func get_jouraku_territories(player, territory_index):
	"""Territories around kyo (4) the player occupies."""
	
	var territory_connections = GameState.board_state["territory_connections"]
	var valid_territory_pool = territory_connections[4]["all"]
	var valid_territories = []
	
	for player_territory in TerritoryHelper.get_player_territories_soldiers_only(player):
		if valid_territory_pool.has(player_territory):
			valid_territories.append(player_territory)
			
	return valid_territories

func get_kyo(player, territory_index):
	return [4]

func _get_territories_with_x_connections_with_at_least_y_soldiers(player: int, x: String, y: int):
	"""x: water, land, all"""
	var territory_connections = GameState.board_state["territory_connections"]
	var board_state =GameState.board_state["territory_tally"]
	var player_territories = GameState.players[player]["territories"]
	var valid_territory_pool = []
	var valid_territories = []
	
	for territory in range(territory_connections.size()):
		if territory_connections[territory][x].size() > 0:
			valid_territory_pool.append(territory)

	for player_territory in player_territories:
		if valid_territory_pool.has(player_territory):
			if board_state[player_territory][player]["soldier"] >= y:
				valid_territories.append(player_territory)

	return valid_territories

func get_suigun_territories(player, territory_index=null):
	"""Get territories where player has >=2 soldiers with water connections."""
	return _get_territories_with_x_connections_with_at_least_y_soldiers(player, "water", 2)

func get_adjacent_selected_water(player, territory_index=null):
	"""Get territories adjacent to selected territory by water."""

	var territory_connections = GameState.board_state["territory_connections"]
	if territory_index == null:
		territory_index = self.last_selected_territory
	var current_connections = territory_connections[territory_index]
	
	# get select territory's adjacent territorries
	return current_connections["water"]

func get_yamagoe_territories(player, territory_index=null):
	"""Get territories where player has >=2 soldiers with as land connections."""
	return _get_territories_with_x_connections_with_at_least_y_soldiers(player, "land", 2)

func get_adjacent_selected_land(player, territory_index=null):
	"""Get territories adjacent to selected territory by land."""

	var territory_connections = GameState.board_state["territory_connections"]
	var current_connections = territory_connections[self.last_selected_territory]
	
	# get select territory's adjacent territorries
	return current_connections["land"]

func get_buntai_territories(player, territory_index=null):
		"""Get territories where player has >=2 soldiers."""
		return _get_territories_with_x_connections_with_at_least_y_soldiers(player, "all", 2)
