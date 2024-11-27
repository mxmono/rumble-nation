extends Node2D

var player_piece_scale = Vector2(1, 1)
var piece_offset = Vector2(15, 0)
var move_to_display = {"num_soldiers": -1, "has_leader": false}


func _ready() -> void:
	pass


func _input(event):
	# skip if only one possible configuration
	if (
		GameState.players[GameState.current_player]["soldier"] + 
		GameState.players[GameState.current_player]["leader"] == 
		move_to_display["num_soldiers"] + int(move_to_display["has_leader"])
	):
		return
	
	# if scrolling during placement phase, show alternate placement popup
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if self.move_to_display["has_leader"]:
				update_move(self.move_to_display["num_soldiers"] + 1, false)
			else:
				update_move(self.move_to_display["num_soldiers"] - 1, true)
		
			draw_pieces()


func update_move(num_soldiers: int, has_leader: bool):
	self.move_to_display["num_soldiers"] = num_soldiers
	self.move_to_display["has_leader"] = has_leader


func draw_pieces():
	
	update_piece_drawing_params_based_on_num_players()
	
	var icon = GameState.players[GameState.current_player]["icon"]
	var icon_leader = GameState.players[GameState.current_player]["icon_leader"]
	var base_offset = Vector2(10, 10)
	
	# draw leader
	if self.move_to_display["has_leader"]:
		var leader_sprite = Sprite2D.new()
		leader_sprite.scale = self.player_piece_scale  * 1.5
		leader_sprite.texture = icon_leader
		leader_sprite.modulate = Color(1, 1, 1, 0.5)
		leader_sprite.position += base_offset
		add_child(leader_sprite)
	
	# draw soldiers
	for i in range(self.move_to_display["num_soldiers"]):
		var piece_sprite = Sprite2D.new()
		piece_sprite.scale = self.player_piece_scale
		piece_sprite.texture = icon
		piece_sprite.modulate = Color(1, 1, 1, 0.5)
		piece_sprite.position += (i + 2 * int(self.move_to_display["has_leader"])) * self.piece_offset + base_offset
		add_child(piece_sprite)


func update_piece_drawing_params_based_on_num_players():
	"""Update how big the pieces should be based on number of players."""
	match GameState.num_players:
		2: self.player_piece_scale = Vector2(1.2, 1.2)
		3: self.player_piece_scale = Vector2(1.2, 1.2)
		4: self.player_piece_scale = Vector2(1, 1)
