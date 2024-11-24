extends Node2D

signal card_effect_incremented(card: Card)
signal card_target_selection_requested(mouse_position: Vector2, valid_opponents: Array, territory_clicked: int)
signal leader_target_selection_requested(mouse_position: Vector2, territory_clicked: int)
signal card_move_selected(moves: Array)

@onready var board_ui = $UI
@onready var place_preview = $UI/PlacePreview
@onready var control_scene = get_node("/root/Game/Control")


func _ready():
	
	# connect territory clicked signal to handle logic here
	board_ui.territory_clicked.connect(_on_territory_clicked)
	board_ui.target_selected.connect(_on_target_selected)
	board_ui.leader_target_selected.connect(_on_leader_target_selected)


# call ui code for territory highlight
func highlight_territories(territories: Array, player: int):
	board_ui.highlight_territories(territories, player)


func unhighlight_territories():
	board_ui.unhighlight_territories()
	

func _on_territory_clicked(territory: int, mouse_position: Vector2):
	# if it's card phase, proceed with card actions
	if GameState.current_phase == GameState.TurnPhase.CARD and GameState.current_card != null:
		execute_card_step(territory, mouse_position)
	
	# if it's placement phase (place or reroll)
	elif GameState.current_phase == GameState.TurnPhase.PLACE or GameState.current_phase == GameState.TurnPhase.REROLL:
		control_scene.dice_selected.emit(
			territory,
			place_preview.move_to_display["num_soldiers"] + int(place_preview.move_to_display["has_leader"]),
			place_preview.move_to_display["has_leader"],
		)
		# reset the moves of the preview
		place_preview.update_move(-1, false)


func execute_card_step(territory_clicked: int, mouse_position: Vector2):
	var card = GameState.current_card
		
	# if card effects are not fully executed
	while card.effect_index < card.effect.size():
		
		var current_step_territories = get_card_step_territories(card)

		# only react if the territory clicked is valid card territories
		if not territory_clicked in current_step_territories:
			return
		
		# select opponent if an opponent is required and hasn't been selected
		if card.selected_opponent == -1 and card.effect[card.effect_index]["player"] == "other":
			# find overlap of valid target and targets available on the clicked territory
			var valid_targets = card.get_valid_targets_on_territory(GameState.current_player, territory_clicked)
			
			# if only 1 valid target, no need for selection, set target directly
			if valid_targets.size() == 1:
				card.selected_opponent = valid_targets[0]
			
			# otherwise pop up a target selection menu and exit the function
			else:
				card_target_selection_requested.emit(mouse_position, valid_targets, territory_clicked)
				return
		
		# if leader card needs opponent selection
		if card.card_type == "leader" and card.get("is_leader_optional_or_undecided") and card.effect_index == 0:
			# only show leader selection window if there are options (ie if only leader is on territory...)
			if TerritoryHelper.get_player_territory_tally(GameState.current_player, territory_clicked)["soldier"] > 0:
				leader_target_selection_requested.emit(mouse_position, territory_clicked)
				return
			else:
				_on_leader_target_selected(true, territory_clicked)
			
		# if clicked territory is one of the valid territories for this card step, take actions
		if territory_clicked in current_step_territories:
			var player_to_deploy = GameState.current_player
			if card.effect[card.effect_index]["player"] == "other":
				player_to_deploy = card.selected_opponent
			
			# update effect (used for cards like buntai <deploy count>, jouraku)
			card.update_effect(GameState.current_player)
			
			# queue up the effect to staged moves
			card.staged_moves.append(
				[
					player_to_deploy,
					territory_clicked,
					card.effect[card.effect_index]["deploy"],
					card.effect[card.effect_index].get("has_leader"),
				]
			)
			
			# emit staged moves if allows emit (for multi-step cards)
			if card.effect[card.effect_index].get("emit"):
				var moves_to_emit = get_unemitted_moves(card)
				card_move_selected.emit(moves_to_emit)
				print("emited early card move: ", str(moves_to_emit))
		
			# update card effect stage index
			card.effect_index += 1
			card_effect_incremented.emit(card)
			
			# break the while loop if territory selection is required for the next move
			if card.effect_index < card.effect.size():
				if card.effect[card.effect_index].get("territory_selection_required"):
					break

	# if after clicking the territory, we have all sequence of moves, can emit the signals
	if card.effect_index == card.effect.size():
		# if the last move has already emitted, don't emit
		if not card.effect[-1].get("emit"):
			var moves_to_emit = get_unemitted_moves(card)
			if moves_to_emit:
				card_move_selected.emit(moves_to_emit)  # handles in turn logic
				print("card move finished, emitted moves: ", moves_to_emit)


func get_card_step_territories(card: Card):
	"""Get eligible territories (to highligh and enable click) for a step."""
	if card.effect_index >= card.effect.size():
		return []
	
	return card.get_card_step_territories(card.effect_index)


func get_unemitted_moves(card: Card) -> Array:
	var moves_to_emit = [card.staged_moves[0]]
	
	# otherwise, emit from last unemitted move to current move
	if card.staged_moves.size() > 1:
		for step in range(1, card.staged_moves.size()):
			# if prev step has emit, restart from current step
			if card.effect[step - 1].get("emit"):
				moves_to_emit = [card.staged_moves[step]]
			# if prev step is not emit, append current step
			else:
				moves_to_emit.append(card.staged_moves[step])
	
	return moves_to_emit


func _on_target_selected(opponent: int, territory_clicked: int):
	GameState.current_card.selected_opponent = opponent
	execute_card_step(territory_clicked, Vector2(0, 0))  # mock mouse position


func _on_leader_target_selected(apply_to_leader: bool, territory_clicked: int):
	var card = GameState.current_card
	if card != null:
		card.apply_to_leader = apply_to_leader
		card.is_leader_optional_or_undecided = false
	
	execute_card_step(territory_clicked, Vector2(0, 0))  # mock mouse position
