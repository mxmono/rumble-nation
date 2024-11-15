class_name Card

extends Button

signal card_selected(card)

@export var card_type: String = "normal"
@export var card_name: String = "Base Card"
@export var card_name_jp: String = "卡片"
@export var description: String = "Description of the card"
var effect = []  # an array of dictionaries of moves
var effect_index = 0  # which step is effect at, 0 = initial, 1 = after 1st step
var staged_moves = []  # staged moves associated with usage of the card, [player, territory_index, deploy_count, has_leader]
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


func is_condition_met(player: int) -> bool:
	"""True if condition is met by player, card can be seelcted; vice versa."""
	return false


func get_valid_targets(player) -> Array:
	"""Array of valid targets/opponents to apply card effect."""
	return []


func get_valid_targets_on_territory(player, territory_index) -> Array:
	"""Overlap of valid targets on clicked territory."""
	
	var target_pool = get_valid_targets(player)
	var valid_targets = []
	for target in target_pool:
		if GameState.players[target]["territories"].has(territory_index):
			valid_targets.append(target)
	
	return valid_targets


func get_card_step_territories(step: int) -> Array:
	"""For each effect_index, get an array of valid territories."""
	return []


func update_effect(player):
	"""Called in every move (before staging), mainly to update next step valid territories."""
	pass


func update_card_on_selection():
	"""Called in _on_card_selected to update effect before emitting the card."""
	pass
