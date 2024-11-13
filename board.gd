extends Node2D

signal card_move_selected(moves)
signal card_move_reverted(moves) # move is an array of [player, territory_index, deploy_count, has_leader]s

# a list of territory Area2D's ordered by assigned points, ie the 1st territory has 2 points
@export var territories = []
# a list of territory Area2D's in their original orders (ie territory1, territory2, ...)
@export var territories_default = []
# dictionary mapping of {points: index}
@export var territory_points_to_index = {}
# dictionary mapping of {index: points}
@export var territory_index_to_points = {}

const CARD_ACTION_PARENT = "/root/GameController/Control/GameButtons/Card/ActionButtons/"
const LEADER_ACTION_PARENT = "/root/GameController/Control/GameButtons/Leader/ActionButtons/"
@onready var confirm_card_button = get_node(CARD_ACTION_PARENT + "ConfirmCardButton")
@onready var reset_card_button = get_node(CARD_ACTION_PARENT + "ResetCardButton")
@onready var confirm_leader_button = get_node(LEADER_ACTION_PARENT + "ConfirmCardButton")
@onready var reset_leader_button = get_node(LEADER_ACTION_PARENT + "ResetCardButton")

func _ready() -> void:
	
	# assign random points to each territory
	assign_points_to_territories()
	
	# conect territory click signals
	for territory in $Map.get_children():
		territory.territory_clicked.connect(_on_territory_clicked)
		territories_default.append(territory)
	
	# connect dice roll signal
	get_node("/root/GameController/Control").dice_rolled.connect(_on_dice_rolled)
	get_node("/root/GameController/Control").dice_selected.connect(_on_dice_selected)
	
	# connect card selection signals (for map highlighting)
	for card_button in get_node("/root/GameController/Control/GameButtons/Card/CardTray").get_children():
		card_button.card_selected.connect(_on_card_selected)
	# TODO
	for card_button in get_node("/root/GameController/Control/GameButtons/Leader/CardTray").get_children():
		card_button.card_selected.connect(_on_card_selected)
	# connect reset card button
	reset_card_button.pressed.connect(_on_card_reset)
	reset_leader_button.pressed.connect(_on_card_reset)

	for territory in $Map.get_children():
		territory_points_to_index[territory.get("territory_points")] = territory.get("territory_index")
		territory_index_to_points[territory.get("territory_index")] = territory.get("territory_points")

func assign_points_to_territories():
	var i = 0
	for territory in $Map.get_children():
		territory.set("territory_points", Settings.board_state["territory_points"][i])
		territory.get_node("PointsLabel").text = str(Settings.board_state["territory_points"][i])
		i += 1
	
	# assemble the territory array ordered by points value
	for p in Array(range(2, 13)):
		for t in $Map.get_children():
			if t.get("territory_points") == p:
				territories.append(t)

func highlight_territories(territory_indices: Array, color = Color(1, 1, 0, 0.5)):
	for territory in $Map.get_children():
		if territory.territory_index in territory_indices:
			var visual_polygon = territory.get_node("Polygon2D")
			var highlight_material = CanvasItemMaterial.new()
			highlight_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			visual_polygon.material = highlight_material
			visual_polygon.color = color

func unhighlight_territories(territory_indices: Array):
	for territory in $Map.get_children():
		if territory.territory_index in territory_indices:
			var visual_polygon = territory.get_node("Polygon2D")
			var original_material
			visual_polygon.material = original_material
			visual_polygon.color = Color(1, 1, 1, 0) 

# Respond to territory clicks
func _on_territory_clicked(territory_index, mouse_position):
	print("Territory clicked: ", territory_index)

	# if it's in territory selection phase from playing a card, emit the selected territory
	var game_controller = get_node("/root/GameController")
	var card = game_controller.card_in_effect
	var current_player = game_controller.current_player
	
	# if we are in card phase
	if game_controller.current_phase == game_controller.TurnPhase.CARD and card != null:
		# only proceed with card effect if clicking on a territory in current valid territories
		# find which territories are eligible for current step
		var current_step_territories = get_card_step_territories(card)
		if not territory_index in current_step_territories:
			return
		
		# eg if we have two moves (size = 2) and index is 0 (initial), or 1 (after 1 move)
		if card.effect_index < card.effect.size():
			# select opponent if an opponent is required and hasn't been selected
			if card.selected_opponent == -1 and card.effect[card.effect_index]["player"] == "other":
				# find overlap of valid target and targets available on the clicked territory
				var valid_targets = card.get_valid_targets_on_territory(current_player, territory_index)
				print(valid_targets)
				
				# if only 1 valid target, no need for selection, set target directly
				if valid_targets.size() == 1:
					card.selected_opponent = valid_targets[0]
				
				# otherwise pop up a target selection menu
				else:
					# temporarily store clicked territory, waiting for target selection in pop up menu
					card.last_selected_territory = territory_index
					# show the target selection menu
					show_target_selection_menu(mouse_position, valid_targets)
					# exit the function
					return
			
			# if it's leader card and requires leader selection
			if card.card_type == "leader" and card.get("is_leader_optional_or_undecided") and card.effect_index == 0:
				card.last_selected_territory = territory_index
				# only show leader selection window if there are options (ie if only leader is on territory...)
				if Settings.board_state["territory_tally"][territory_index][current_player]["soldier"] > 0:
					show_leader_selection_window(mouse_position)
				else:
					_on_apply_to_leader_selected(true)
				return
			
			# if clicked territory is one of the valid territories for this card step, take actions
			if territory_index in current_step_territories:
				card.last_selected_territory = territory_index
				# check which player to deploy based on card step player keyword
				var player_to_deploy = current_player
				if card.effect[card.effect_index]["player"] == "other":
					player_to_deploy = card.selected_opponent
				
				# update effect (used for cards like buntai <deploy count>, jouraku)
				card.update_effect(current_player)
				
				# queue up the effect to staged moves
				card.staged_moves.append(
					[player_to_deploy, territory_index, card.effect[card.effect_index]["deploy"], card.effect[card.effect_index].get("has_leader")]
				)
				
				# emit staged moves if allows emit (for multi-step cards)
				if card.effect[card.effect_index].get("emit"):
					var moves_to_emit = get_unemitted_moves(card)
					card_move_selected.emit(moves_to_emit)
					print("emited early card move: ", str(moves_to_emit))
				
				# for cards like jouraku, the user can confirm halfway (not realizing full potential)
				enable_early_action_button_if_valid(card)
				
				# once the action is queued (click is registered), unhighlight all territories
				unhighlight_territories(self.territory_index_to_points.keys())
			
				# update card effect stage index
				card.effect_index += 1
				
				# check if next step requires selection
				while card.effect_index < card.effect.size():
					# if does not require selection, loop until next one that requires selection
					if not card.effect[card.effect_index]["territory_selection_required"]:
						player_to_deploy = current_player
						if card.effect[card.effect_index]["player"] == "other":
							player_to_deploy = card.selected_opponent
						# TODO: territory_index will carry over from prev selected step by default
						# update effect (used for cards like buntai <deploy count>, jouraku)
						card.update_effect(current_player)
						card.staged_moves.append(
							[player_to_deploy, territory_index, card.effect[card.effect_index]["deploy"], card.effect[card.effect_index].get("has_leader")]
						)
						
						# emit staged moves if allows emit (for multi-step cards)
						if card.effect[card.effect_index].get("emit"):
							var moves_to_emit = get_unemitted_moves(card)
							card_move_selected.emit(moves_to_emit)
							print("emited early card move: ", str(moves_to_emit))
							enable_early_action_button_if_valid(card)
							
						card.effect_index += 1
					else:
						break
				
				print(card.staged_moves)
				print("current effect index: ", card.effect_index)
				
				# if there is still a next step, highlight next eligible territories
				# eg if we just took step 1, card_effect_index + 1 == 1, size = 2 (if two steps)
				if card.effect_index < card.effect.size():
					var next_step_territories = get_card_step_territories(card)
					print("next step territories: ", next_step_territories)
					# highlight the next eligible territories
					var player_color = Settings.players[current_player]["color"]
					highlight_territories(next_step_territories, player_color)
	
				# if after clicking the territory, we have all sequence of moves, can emit the signals
				elif card.effect_index == card.effect.size():
					# if the last move has already emitted, don't emit
					if not card.effect[-1].get("emit"):
						var moves_to_emit = get_unemitted_moves(card)
						if moves_to_emit:
							card_move_selected.emit(moves_to_emit)  # handles in game controller, territroy
					
					# unhiglight all territories
					unhighlight_territories(self.territory_index_to_points.keys())

#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("click position: ", event.position)
		
# show target selection menu when clicked on a valid territory
func show_target_selection_menu(mouse_position, valid_opponents):
	# clean up if needed
	if has_node("PopUp"):
		$PopUp.queue_free()
	
	# inistantiate the popup
	var target_selection_popup = preload("res://popup.tscn").instantiate()
	
	# generate options per valid opponents
	for valid_opponent in valid_opponents:
		var opponent_name = Settings.players[valid_opponent]["name"]
		var target_button = Button.new()
		target_button.text = opponent_name
		target_button.icon = Settings.players[valid_opponent]["icon"]
		target_button.name = "Player" +  str(valid_opponent)
		
		# connect button to pressed signal
		target_button.pressed.connect(_on_target_selected.bind(valid_opponent))
		
		# add the buttons to pop up menu
		target_selection_popup.get_node("PopupPanel/VBoxContainer").add_child(target_button)
	
	# add pop up to scene tree
	add_child(target_selection_popup)
	target_selection_popup.get_node("PopupPanel").popup()
	target_selection_popup.get_node("PopupPanel").position = mouse_position

func show_leader_selection_window(mouse_position):
	# clean up if needed
	if has_node("PopUp"):
		$PopUp.queue_free()
	
	# inistantiate the popup
	var current_player = get_node("/root/GameController").current_player
	var target_selection_popup = preload("res://popup.tscn").instantiate()
	
	for i in range(2):
		var button = Button.new()
		button.text = ["Apply to Soldiers Only", "Apply to Leader"][i]
		button.icon = Settings.players[current_player][["icon", "icon_leader"][i]]
	
		# connect button to pressed signal, 0=false=do not apply to leader
		button.pressed.connect(_on_apply_to_leader_selected.bind(bool(i)))
	
		# add the buttons to pop up menu
		target_selection_popup.get_node("PopupPanel/VBoxContainer").add_child(button)

	# add pop up to scene tree
	add_child(target_selection_popup)
	target_selection_popup.get_node("PopupPanel").popup()
	target_selection_popup.get_node("PopupPanel").position = mouse_position

# when button on target selection pop up is selected
func _on_target_selected(valid_opponent):
	var card = get_node("/root/GameController").card_in_effect
	if card != null:
		card.selected_opponent = valid_opponent
		if has_node("PopUp"):
			$PopUp.queue_free()
		_on_territory_clicked(card.last_selected_territory, Vector2(0, 0))  # mock mouse position

func _on_apply_to_leader_selected(apply_to_leader: bool):
	var card = get_node("/root/GameController").card_in_effect
	if card != null:
		card.apply_to_leader = apply_to_leader
		card.is_leader_optional_or_undecided = false
		if has_node("PopUp"):
			$PopUp.queue_free()
		_on_territory_clicked(card.last_selected_territory, Vector2(0, 0))

func get_card_step_territories(card):
	"""Get eligible territories (to highligh and enable click) for a step."""
	if card.effect_index >= card.effect.size():
		return []
	
	# if territory in "occupied", pass null to territory, since function is independent of it
	# if territroy is "adjacent" pass previous move's selected territory
	var current_player = get_node("/root/GameController").current_player
	var territory_arg = null
	if card.effect[card.effect_index]["territory"].begins_with("adjacent"):
		territory_arg = card.last_selected_territory
	var valid_territories = card.territory_func_mapping[card.effect[card.effect_index]["territory"]].call(
		current_player, territory_arg
	)
	
	return valid_territories

# get which moves to emit, start from last unemitted move
func get_unemitted_moves(card) -> Array:
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

# highlight relevant territories on card selection
func _on_card_selected(card):
	# highlight which territories are eligible when a card is selected
	var current_player = get_node("/root/GameController").current_player
	
	# highlight the first move
	var territories = card.territory_func_mapping[card.effect[0]["territory"]].call(
		current_player, null
	)
	
	var player_color = Settings.players[current_player]["color"]
	highlight_territories(territories, player_color)

func _on_card_reset():
	# reverse deployment
	var game_controller = get_node("/root/GameController")
	var card = game_controller.card_in_effect
	#if game_controller.current_phase == game_controller.TurnPhase.CONFIRM_OR_RESET_CARD:
	var revert_moves = []
	# card_moves_stage is [[player, territory_index, deploy_count, has_leader], ...]
	for i in range(card.staged_moves.size()):
		var move = card.staged_moves[i]
		revert_moves.append([move[0], move[1], -move[2], move[3]])
	
	# clear moves associated with the card itself and reset move count
	card.reset_card()

	if get_parent().has_node("TargetPopUpWindow"):
		$TargetPopUpWindow.queue_free()
	
	# emit revert signal
	card_move_reverted.emit(revert_moves)
	print("emitted revert:", revert_moves)
	
	# reintroduce effects on card selected (eg going back to card selected status)
	_on_card_selected(card)

# UI:highlights territories eligible for dice moves
func _on_dice_rolled(dice_results, move_options):
	# first unhighlight everything (eg if this is a reroll)
	unhighlight_territories(self.territory_index_to_points.keys())
	
	# then highlight relevant territories
	var territories = []
	for move_option in move_options:
		territories.append(move_option["territory_index"])
	
	# get player color
	var current_player = get_node("/root/GameController").current_player
	var player_color = Settings.players[current_player]["color"]
	player_color.a = 0.3
	highlight_territories(territories, player_color)

# UI: unhighlight all territories when dice option is selected
func _on_dice_selected(territory_index: int, deploy_count: int, is_leader: bool):
	unhighlight_territories(self.territory_index_to_points.keys())

func enable_early_action_button_if_valid(card):
	if card.effect[card.effect_index].get("finish_allowed"):
		confirm_card_button.disabled = false
		reset_card_button.disabled = false
		confirm_leader_button.disabled = false
		reset_leader_button.disabled = false
