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
	"occupied_other_adjacent_to_self": get_other_player_adjacent_territories,
	"adjacent_occupied": get_adjacent_occupied_territories,
}
var selected_opponent: int = -1 # to which opponent is the card targeting

func _ready() -> void:
	$ENTitle.text = card_name
	$JPTitle.text = card_name_jp
	$Description.text = description
	
	self.pressed.connect(_on_card_selected)
	
func update_valid_targets():
	var player_piece_icons = get_node("/root/GameController/MenuCanvas").player_piece_icons

	# draw eligible opponents in TargetHBox if condition met
	var current_player = get_node("/root/GameController").current_player
	
	# target selection, only needed when more than 2 players
	if Settings.num_players > 2:
		if is_condition_met(current_player):
			var valid_targets = get_valid_targets(current_player)
			if valid_targets.size() > 0:
				# if there are valid targets, add those buttons
				for target in valid_targets:
					var target_icon = player_piece_icons[target]
					var target_button = Button.new()
					#target_button.texture_normal = target_icon
					target_button.text = str(target)
					$TargetHBox.add_child(target_button)
					print(target)

func _on_card_selected():
	if Settings.num_players == 2:
		self.selected_opponent = 3 - get_node("/root/GameController").current_player
	
	card_selected.emit(self)

func is_condition_met(player) -> bool:
	return false

func get_valid_targets(player) -> Array:
	return []

func get_occupied_territories(player, territroy_index=null, other_player=null) -> Array:
	"""Returns an array territory index."""
	
	# get variables	
	var territory_connections = get_node("/root/GameController/Map").territory_connections

	return Settings.players[player]["territories"]

func get_adjacent_territories(player, territory_index, other_player=null) -> Array:
	# error handling
	if territory_index == null:
		return []

	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var current_connections = territory_connections[territory_index]
	
	# get select territory's adjacent territorries
	return current_connections["all"]

func get_adjacent_occupied_territories(player, territory_index, other_player) -> Array:
	"""Get other_player's adjacent territories occupied by player given a territory_index."""
	# it's the reverse of get_other_player_adjacent_territories
	return get_other_player_adjacent_territories(other_player, territory_index, player)

func get_other_player_adjacent_territories(player, territory_index, other_player) -> Array:
	"""Find territories other_player occupies that are adjacent to player territory."""
	# get variables
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var player_territories = Settings.player[player]["territories"]
	var other_player_territories = Settings.player[player]["territories"]
	
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
				valid_territories.append(connected_territory)
	
	return valid_territories
	
