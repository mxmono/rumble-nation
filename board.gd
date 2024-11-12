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
# default connections
@export var territory_connections = [
	{"land": [], "water": [1, 2, 3]},		# 0
	{"land": [], "water": [0, 3, 4]},		# 1
	{"land": [], "water": [0]},				# 2
	{"land": [4], "water": [0, 1]},			# 3
	{"land": [3, 5, 6], "water": [1]},		# 4
	{"land": [4, 6, 7], "water": []},		# 5
	{"land": [4, 5, 7, 9], "water": []},	# 6
	{"land": [5, 6, 8, 9], "water": []},	# 7
	{"land": [7, 9], "water": [10]},		# 8
	{"land": [6, 7, 8], "water": []},		# 9
	{"land": [], "water": [8]},				# 10
]
var board_state = []  # an array of territory tallies

const CARD_ACTION_PARENT = "/root/GameController/Control/GameButtons/Card/ActionButtons/"
@onready var card_finish_move_button = get_node(CARD_ACTION_PARENT + "FinishCardMoveButton")
@onready var reset_card_button = get_node(CARD_ACTION_PARENT + "ResetCardButton")

func _ready() -> void:
	
	# assign random points to each territory
	assign_points_to_territories()
	
	for i in range(territory_connections.size()):
		territory_connections[i]["all"] = territory_connections[i]["land"] + territory_connections[i]["water"]
	
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
	# connect reset card button
	reset_card_button.pressed.connect(_on_card_reset)
	# connect finish move button
	card_finish_move_button.pressed.connect(_on_card_finish_move_button_pressed)

	for territory in $Map.get_children():
		territory_points_to_index[territory.get("territory_points")] = territory.get("territory_index")
		territory_index_to_points[territory.get("territory_index")] = territory.get("territory_points")
		board_state.append(territory.territory_tally)

func _process(delta: float) -> void:
	# update board state
	board_state = []
	for territory in self.territories_default:
		board_state.append(territory.territory_tally)

func assign_points_to_territories():
	# generate an array of randomized points
	var points = Array(range(2, 13))  # 2 to 12
	points.shuffle()
	var i = 0
	for territory in $Map.get_children():
		territory.set("territory_points", points[i])
		territory.get_node("PointsLabel").text = str(points[i])
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
		# eg if we have two moves (size = 2) and index is 0 (initial), or 1 (after 1 move)
		if card.effect_index < card.effect.size():
			# select opponent if an opponent is required and hasn't been selected
			if card.selected_opponent == -1 and card.effect[card.effect_index]["player"] == "other":
				# find overlap of valid target and targets available on the clicked territory
				var target_pool = card.get_valid_targets(current_player)
				var valid_targets = []
				for target in target_pool:
					if Settings.players[target]["territories"].has(territory_index):
						valid_targets.append(target)
				
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
			
			# only proceed with card effect if clicking on a territory in current valid territories
			# find which territories are eligible for current step
			var current_step_territories = get_card_step_territories(card)
			
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
					[player_to_deploy, territory_index, card.effect[card.effect_index]["deploy"], false]
				)
				
				# for cards like jouraku, the user can confirm halfway (not realizing full potential)
				enable_early_finish_button_if_valid(card)
				
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
							[player_to_deploy, territory_index, card.effect[card.effect_index]["deploy"], false]
						)
						card.effect_index += 1
					else:
						break
				
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
					card_move_selected.emit(card.staged_moves)  # handles in game controller, territroy
					# unhiglight all territories
					card_finish_move_button.disabled = true
					unhighlight_territories(self.territory_index_to_points.keys())

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("click position: ", event.position)
		
# show target selection menu when clicked on a valid territory
func show_target_selection_menu(mouse_position, valid_opponents):
	print("passed mouse position:", mouse_position)
	# instantiate the target selection pop up
	var target_selection_popup = preload("res://target_popup.tscn").instantiate()
	
	# generate a button for each valid target
	for valid_opponent in valid_opponents:
		var opponent_name = Settings.players[valid_opponent]["name"]
		var target_button = Button.new()
		target_button.text = opponent_name
		target_button.icon = Settings.players[valid_opponent]["icon"]
		target_button.name = "Player" +  str(valid_opponent)
		
		# connect button to pressed signal
		target_button.pressed.connect(_on_target_selected.bind(valid_opponent))
		
		# add the buttons to pop up menu
		target_selection_popup.get_node(
			"PopUpPanel/MarginContainer/VBoxContainer/TargetButtons"
		).add_child(target_button)

	# set pop up menu position
	target_selection_popup.global_position = mouse_position

	# add the pop up menu
	add_child(target_selection_popup)
	
	# pop up the target selection window
	target_selection_popup.show()

# when button on target selection pop up is selected
func _on_target_selected(valid_opponent):
	var card = get_node("/root/GameController").card_in_effect
	if card != null:
		card.selected_opponent = valid_opponent
		$TargetPopUpWindow.queue_free()
		_on_territory_clicked(card.last_selected_territory, Vector2(0, 0))  # mock mouse position

func get_card_step_territories(card):
	"""Get eligible territories (to highligh and enable click) for a step."""
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

# highlight relevant territories on card selection
func _on_card_selected(card):
	# highlight which territories are eligible when a card is selected
	var current_player = get_node("/root/GameController").current_player
	
	# UI: enable finish move button if allowed
	if card.early_finish_enabled:
		card_finish_move_button.visible = true
		card_finish_move_button.disabled = true
	
	# highlight the first move
	var territories = card.territory_func_mapping[card.effect[0]["territory"]].call(
		current_player, null
	)
	var player_color = Settings.players[current_player]["color"]
	highlight_territories(territories, player_color)

# when finishing move early, emit card moves and unhighlight territories
func _on_card_finish_move_button_pressed():
	var card = get_node("/root/GameController").card_in_effect
	card_move_selected.emit(card.staged_moves)
	card_finish_move_button.disabled = true
	unhighlight_territories(self.territory_index_to_points.keys())

func _on_card_reset():
	# reverse deployment
	var game_controller = get_node("/root/GameController")
	var card = game_controller.card_in_effect
	if game_controller.current_phase == game_controller.TurnPhase.CONFIRM_OR_RESET_CARD:
		var revert_moves = []
		# card_moves_stage is [[player, territory_index, deploy_count, has_leader], ...]
		for i in range(card.staged_moves.size()):
			var move = card.staged_moves[i]
			revert_moves.append([move[0], move[1], -move[2], move[3]])
		
		# clear moves associated with the card itself and reset move count
		card.staged_moves = []
		card.effect_index = 0
		card.selected_opponent = -1
		card.last_selected_territory = -1
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

func enable_early_finish_button_if_valid(card):
	if card.early_finish_enabled:
		if card.effect[card.effect_index]["finish_allowed"]:
			card_finish_move_button.disabled = false
			card_finish_move_button.visible = true
		else:
			card_finish_move_button.disabled = true
			card_finish_move_button.visible = true
