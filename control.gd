extends Control

signal dice_rolled(dice_results: Array, move_options: Array)
signal dice_selected(territory_index: int, deploy_count: int, is_leader: bool)
signal card_selected(card: Card)  # broadcast from ui
signal card_move_reverted(moves: Array)  # broadcast from ui
signal card_move_confirmed()  # broadcast from ui

@onready var control_ui = $UI


# Called when the node enters the scene tree for the first time.
func _ready():
	# connect UI roll dice buttons to roll logic
	control_ui.roll_dice_requested.connect(_on_roll_dice_requested)
	control_ui.dice_option_selected.connect(_on_dice_option_selected)
	control_ui.card_selected.connect(_on_card_selected)
	control_ui.card_move_reverted.connect(_on_card_move_reverted)
	control_ui.card_move_confirmed.connect(_on_card_move_confirmed)


# Handle the dice roll button press
func _on_roll_dice_requested():
	
	# roll the dice, get results, and possible moves
	var dice_results = [roll_dice(), roll_dice(), roll_dice()]
	dice_results.sort()
	var move_options = combine_dice(dice_results)
	
	# update game state
	GameState.update_dice(dice_results)
	
	# emit signal
	dice_rolled.emit(dice_results, move_options)


func roll_dice() -> int:
		randomize()
		return randi() % 6 + 1


func combine_dice(dice_results: Array) -> Array:
	"""Combine three dice results into move options."""
	var current_player = GameState.current_player
	var territory_points = GameState.board_state["territory_points"]
	
	# calculate all move options
	var move_options = []
	for i in range(3):
		# deploy count is bound by how many pieces are left
		var deploy_count = (dice_results[i % 3] + 1) / 2
		deploy_count = min(
			deploy_count,
			GameState.players[current_player]["soldier"] + GameState.players[current_player]["leader"]
		)
		var territory_score = dice_results[(i + 1) % 3] + dice_results[(i + 2) % 3]
		var territory_index = territory_points.find(territory_score)
		var option = {
			"deploy_count": deploy_count,
			"territory_score": territory_score, 
			"territory_index": territory_index
		}
		# only add if the move is not repeated
		if not move_options.has(option):
			move_options.append(option)

	return move_options


func _on_dice_option_selected(i, has_leader):
	var dice_move_options = combine_dice(GameState.current_dice)

	# kind of broadcasting dice_option_selected from ui component to other nodes
	dice_selected.emit(
		dice_move_options[i]["territory_index"],
		dice_move_options[i]["deploy_count"],
		has_leader,
	)


func _on_card_selected(card: Card):
	card_selected.emit(card)


func _on_card_move_reverted(moves: Array):
	card_move_reverted.emit(moves)


func _on_card_move_confirmed():
	card_move_confirmed.emit()
