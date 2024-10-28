extends Node2D

signal territory_clicked(territory_name)
signal piece_placed(piece)

@export var territory_name: String = self.name
@export var territory_index: int = 0
@export var territory_points: int = 0
@export var player_piece_icons = {
	1: preload("res://icons/cat.webp"),
	2: preload("res://icons/bird.webp"),
}
@export var player_piece_scale = Vector2(0.1, 0.1)

@export var territory_tally = {
	1: {"soldier": 0, "leader": 0},
	2: {"soldier": 0, "leader": 0},
	3: {"soldier": 0, "leader": 0},
	4: {"soldier": 0, "leader": 0},
}
var piece_offset = Vector2(15, 0)
var player_piece_offset = Vector2(0, 30)

@onready var collision_polygon = $CollisionPolygon2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the input_event signal from Area2D to handle clicks
	#$Area2D.input_event.connect(_on_territory_clicked)
	var control_scene = get_node("/root/GameController/Control")
	control_scene.dice_selected.connect(_on_dice_selected)

func add_piece_sprite(player, n, has_leader):
	var icon = player_piece_icons[player]
	var piece_container = $PieceContainer
	var n_soldiers = n
	
	# first draw soldiers
	if has_leader:
		n_soldiers -= 1
	for i in range(n_soldiers):
		var piece_sprite = Sprite2D.new()
		piece_sprite.scale = player_piece_scale
		piece_sprite.texture = icon
		piece_sprite.position = get_piece_position(
			player, territory_tally[player]["soldier"]
		) + piece_offset * i
		piece_container.add_child(piece_sprite)
	
	# draw leader in the front if there is a leader
	if has_leader:
		var leader_sprite = Sprite2D.new()
		leader_sprite.scale = player_piece_scale * 1.5
		leader_sprite.texture = icon
		leader_sprite.position = Vector2(-30, 0) +  (player - 1) * player_piece_offset
		piece_container.add_child(leader_sprite)
		
func add_reinforcement_sprite(player, n):
	var icon = player_piece_icons[player]
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
	var offset = piece_offset * existing_n_pieces + (player - 1) * player_piece_offset
	return Vector2(0, 0) + offset

# Handles click events on the territory
func _on_territory_clicked(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Clicked territory: ", territory_name)
		territory_clicked.emit(territory_name)

func _on_dice_selected(territory_option, deploy_option, has_leader):
	if self.territory_points == territory_option:
		var game_controller = get_node("/root/GameController")
		var current_player = game_controller.current_player
		# add piece needs to be before tally update due to position update
		add_piece_sprite(current_player, deploy_option, has_leader)
		if has_leader:
			territory_tally[current_player]["soldier"] += deploy_option - 1
			territory_tally[current_player]["leader"] += 1
		else:
			territory_tally[current_player]["soldier"] += deploy_option
		#update_piece_label()

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
	for territory_index in current_connections["land"] + current_connections["water"]:
		var territory_to_reinforce = territories_default[territory_index - 1]
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
		[str(self.territory_index + 1), str(self.territory_points), str(player), str(pieces_to_reinforce)]
	)
