extends Node2D

signal territory_clicked(territory_index)
signal piece_placed(piece)

@export var territory_name: String = self.name
@export var territory_index: int = 0
@export var territory_points: int = 0
@export var player_piece_scale = Vector2(0.1, 0.1)

@export var territory_tally = []
var piece_offset = Vector2(15, 0)
var player_piece_offset = Vector2(0, 30)

var original_material  # Store the original material
var highlight_material  # Material used for highlighting with blend mode

@onready var collision_polygon = $CollisionPolygon2D
@onready var visual_polygon = $Polygon2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in range(Settings.num_players):
		territory_tally.append({"soldier": 0, "leader": 0})
	
	# Set the points of the visual Polygon2D to match the CollisionPolygon2D
	visual_polygon.polygon = collision_polygon.polygon
	visual_polygon.position = collision_polygon.position
	visual_polygon.color = Color(1, 1, 1, 0)

	# Create a new CanvasItemMaterial for highlighting
	highlight_material = CanvasItemMaterial.new()
	highlight_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	
	# highlight territory on hover
	#self.mouse_entered.connect(_on_mouse_entered)
	#self.mouse_exited.connect(_on_mouse_exited)
	
	# Connect the input_event signal from Area2D to handle clicks
	self.input_event.connect(_on_territory_click)
	
	# connect dice selection
	var control_scene = get_node("/root/GameController/Control")
	control_scene.dice_selected.connect(_on_dice_selected)
	
	# connect card selection
	var board_scene = get_node("/root/GameController/Map")
	board_scene.card_move_selected.connect(_on_card_move_selected)
	board_scene.card_move_reverted.connect(_on_card_move_reverted)
	
	# get card selected signal to highlight those territories on the map
	for card_button in get_node("/root/GameController/Control/GameButtons/Card").get_children():
		if card_button.name.begins_with("Card"):
			card_button.card_selected.connect(_on_card_selected)

func highlight_territory():
	visual_polygon.material = highlight_material
	visual_polygon.color = Color(1, 1, 0, 0.5)

func unhighlight_territory():
	visual_polygon.material = original_material
	visual_polygon.color = Color(1, 1, 1, 0) 

#func _on_mouse_entered():
	#highlight_territory()
#
#func _on_mouse_exited():
	#unhighlight_territory()

func draw_piece_sprites():
	"""Redraw all deployments based on territory_tally.
	Redrawing all is beneficial due to resets and reverts."""

	var piece_container = $PieceContainer
	var num_players = Settings.num_players
	
	# clear existing pieces if any:
	for piece in piece_container.get_children():
		piece.queue_free()
	
	# first draw soldiers
	for player in range(territory_tally.size()):
		if player > num_players:
			continue
		var icon = Settings.player_piece_icons[player]
		for i in range(territory_tally[player]["soldier"]):
			var piece_sprite = Sprite2D.new()
			piece_sprite.scale = player_piece_scale
			piece_sprite.texture = icon
			piece_sprite.position = i * piece_offset +  (player) * player_piece_offset
			piece_container.add_child(piece_sprite)

		# draw leader in the front if there is a leader
		if territory_tally[player]["leader"] > 0:
			var leader_sprite = Sprite2D.new()
			leader_sprite.scale = player_piece_scale * 1.5
			leader_sprite.texture = icon
			leader_sprite.position = Vector2(-30, 0) +  (player) * player_piece_offset
			piece_container.add_child(leader_sprite)
		
func add_reinforcement_sprite(player, n):
	"""Given which player + pieces, draw the reinforcemnet sprites on territory. 
	Relies on territory_tally before the pieces are added to tally."""
	var icon = Settings.player_piece_icons[player]
	var piece_container = $PieceContainer

	for i in range(n):
		var piece_sprite = Sprite2D.new()
		piece_sprite.scale = player_piece_scale * 0.5
		piece_sprite.texture = icon
		piece_sprite.position = get_piece_position(
			player, territory_tally[player]["soldier"]
		) + piece_offset * i + Vector2(15, 0)
		piece_container.add_child(piece_sprite)

func get_piece_position(player, existing_n_pieces) -> Vector2:
	var offset = piece_offset * existing_n_pieces + (player) * player_piece_offset
	return Vector2(0, 0) + offset

# Handles click events on the territory
func _on_territory_click(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		territory_clicked.emit(territory_index)

func _on_dice_selected(territory_index, deploy_count, has_leader):
	# only take action if this is the territory that got deployed
	var current_player = get_node("/root/GameController").current_player
	if self.territory_index == territory_index:
		_on_deployed(current_player, territory_index, deploy_count, has_leader)

func _on_card_selected(card):
	# highlight which territories are eligible when a card is selected
	var current_player = get_node("/root/GameController").current_player
	
	# highlight the first move
	#if card.effect[0]["player"] == "current":
	print(card.selected_opponent)
	print(card.territory_func_mapping[card.effect[0]["territory"]].call(
		current_player, null, card.selected_opponent
	))
	if self.territory_index in card.territory_func_mapping[card.effect[0]["territory"]].call(
		current_player, null, card.selected_opponent
	):
		highlight_territory()

func _on_deployed(player, territory_index, deploy_count, has_leader):
	"""This function alone should handle changes between deployment states."""
	
	# get current player
	var game_controller = get_node("/root/GameController")

	# update tally
	if has_leader:
		if deploy_count >= 0:  # normal game state, add pieces
			territory_tally[player]["soldier"] += deploy_count - 1
			territory_tally[player]["leader"] += 1
		else:  # when reverting or removing pieces, deploy count is negative
			# eg, when removing 2 pieces (deploy count = -2) with leader, remove 1 from soldier
			territory_tally[player]["soldier"] += (deploy_count + 1)
	else:
		territory_tally[player]["soldier"] += deploy_count
	
	# update territories tagged to the player
	if deploy_count > 0:  # if normal game play, add territory to the list if not already there
		if not self.territory_index in Settings.players[player]["territories"]:
			Settings.players[player]["territories"].append(self.territory_index)
		# update piece count of the player
	
	# if removing pieces and there are no pieces left on this territory, remove
	elif deploy_count < 0:
		if territory_tally[player]["soldier"] + territory_tally[player]["leader"] <= 0:
			Settings.players[player]["territories"].erase(self.territory_index)
	
	# update player piece count
	game_controller.update_player_piece_count(player, deploy_count, has_leader)
			
	# redraw sprites based on latest tally
	draw_piece_sprites()

func _on_card_move_selected(moves):
	# moves is [[player, territory_index, deploy_count, has_leader], ...]
	for move in moves:
		if self.territory_index == move[1]:
			# update the tally and sprite
			_on_deployed(move[0], self.territory_index, move[2], move[3])
		
	# UI: turn off the highlight TODO
	unhighlight_territory() 

func _on_card_move_reverted(moves):
	 # move is an array of [player, territory_index, deploy_count, has_leader]s
	for move in moves:
		if self.territory_index == move[1]:
			_on_deployed(move[0], self.territory_index, move[2], move[3])
	
	# UI: highlight territory again (retrigger effect when card first selected)
	var card = get_node("/root/GameController").card_in_effect
	_on_card_selected(card)

func reinforce(num_players, player):
	"""Reinforce to all adjacent territories."""
	# get connected territories and how many pieces to reinforce
	var territory_connections = get_node("/root/GameController/Map").territory_connections
	var current_connections = territory_connections[self.territory_index]
	var pieces_to_reinforce = 1
	if num_players > 2:
		pieces_to_reinforce = 2
	
	# loop through territories to reinforce
	var territories_default = get_node("/root/GameController/Map").territories_default
	for territory_index in current_connections["all"]:
		var territory_to_reinforce = territories_default[territory_index]
		# only reinforce to bigger tiles with current player's pieces
		if territory_to_reinforce.get("territory_points") > self.territory_points:
			var tally = territory_to_reinforce.get("territory_tally")[player]
			if tally["soldier"] + tally["leader"] > 0:
				territory_to_reinforce.receive_reinforcements(pieces_to_reinforce, player)

func receive_reinforcements(pieces_to_reinforce, player):
	"""Receive reinforcements at scoring phase."""
	add_reinforcement_sprite(player, pieces_to_reinforce)
	territory_tally[player]["soldier"] += pieces_to_reinforce
	print("territory %s with points %s received player %s's %s reinforcements" % 
		[str(self.territory_index), str(self.territory_points), str(player), str(pieces_to_reinforce)]
	)
