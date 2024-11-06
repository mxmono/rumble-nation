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
# storing territories selected for card purposes, when a card is used, reset to empty
var territories_selected = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for territory in $Map.get_children():
		territory.territory_clicked.connect(_on_territory_clicked)
		territories_default.append(territory)
	
	assign_points_to_territories()
	
	for i in range(territory_connections.size()):
		territory_connections[i]["all"] = territory_connections[i]["land"] + territory_connections[i]["water"]
	
	for territory in $Map.get_children():
		territory_points_to_index[territory.get("territory_points")] = territory.get("territory_index")
		territory_index_to_points[territory.get("territory_index")] = territory.get("territory_points")
		
	# connect reset card button
	get_node("/root/GameController/Control/GameButtons/Card/ResetCardButton").pressed.connect(_on_card_reset)

# Randomly assign 2 to 12 to each territory
func assign_points_to_territories():
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

func highlight_territories(territory_indices: Array):
	for territory in $Map.get_children():
		if territory.territory_index in territory_indices:
			var visual_polygon = territory.get_node("Polygon2D")
			var highlight_material = CanvasItemMaterial.new()
			highlight_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
			visual_polygon.material = highlight_material
			visual_polygon.color = Color(1, 1, 0, 0.5)

func unhighlight_territories(territory_indices: Array):
	for territory in $Map.get_children():
		if territory.territory_index in territory_indices:
			var visual_polygon = territory.get_node("Polygon2D")
			var original_material
			visual_polygon.material = original_material
			visual_polygon.color = Color(1, 1, 1, 0) 

# Respond to territory clicks
func _on_territory_clicked(territory_index):
	print("Territory clicked: ", territory_index)

	# if it's in territory selection phase from playing a card, emit the selected territory
	var game_controller = get_node("/root/GameController")
	var card = game_controller.card_in_effect
	var current_player = game_controller.current_player
	
	# if we are in card phase
	if game_controller.current_phase == game_controller.TurnPhase.CARD and card != null:
		# eg if we have two moves (size = 2) and index is 0 (initial), or 1 (after 1 move)
		if card.effect_index < card.effect.size():
			# only proceed with card effect if clicking on a territory in current valid territories
			# find which territories are eligible for current step
			var current_step_territories = get_card_step_territories(card)
			
			# if clicked territory is one of the valid territories for this card step, take actions
			if territory_index in current_step_territories:
				# check which player to deploy based on card step player keyword
				var player_to_deploy = current_player
				if card.effect[card.effect_index]["player"] == "other":
					player_to_deploy = card.selected_opponent
				
				# queue up the effect to staged moves
				card.staged_moves.append(
					[player_to_deploy, territory_index, card.effect[card.effect_index]["deploy"], false]
				)
				
				# once the action is queued (click is registered), unhighlight the territories
				unhighlight_territories(current_step_territories)
			
				# update card effect stage index
				card.effect_index += 1

				# if there is still a next step, highlight next eligible territories
				# eg if we just took step 1, card_effect_index + 1 == 1, size = 2 (if two steps)
				if card.effect_index < card.effect.size():
					var next_step_territories = get_card_step_territories(card)
					# highlight the next eligible territories
					highlight_territories(next_step_territories)
	
				# if after clicking the territory, we have all sequence of moves, can emit the signals
				if card.effect_index == card.effect.size():
					card_move_selected.emit(card.staged_moves)  # handles in game controller, territroy

func get_card_step_territories(card):
	"""Get eligible territories (to highligh and enable click) for a step."""
	# if territory in "occupied", pass null to territory, since function is independent of it
	# if territroy is "adjacent" pass previous move's selected territory
	var current_player = get_node("/root/GameController").current_player
	var territory_arg = null
	if card.effect[card.effect_index]["territory"].begins_with("adjacent"):
		territory_arg = card.staged_moves[card.effect_index - 1][1]
	
	var valid_territories = card.territory_func_mapping[card.effect[card.effect_index]["territory"]].call(
		current_player, territory_arg, card.selected_opponent
	)
	
	return valid_territories

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
		
		# emit revert signal
		card_move_reverted.emit(revert_moves)
		print("emitted revert:", revert_moves)

# Handle the piece being placed on a territory
func _on_piece_placed(piece):
	print("Piece placed: ", piece.name)
	# Add logic to handle turns, scoring, or ownership changes
