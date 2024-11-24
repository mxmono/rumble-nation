extends Node

signal territory_clicked(territory: int, mouse_position: Vector2)
signal target_selected(selected_opponent: int)
signal leader_target_selected(apply_to_leader: bool, territory_clicked: int)

@onready var game_scene: Node2D = get_node("/root/Game")
@onready var board_scene: Node2D = get_node("/root/Game/Board")
@onready var control_scene: Control = get_node("/root/Game/Control")
@onready var territory_nodes: Node2D = board_scene.get_node("Territories")
@onready var tilemap: TileMapLayer = board_scene.get_node("Map")
@onready var tilemap_constant: TileMapLayer = board_scene.get_node("MapConstant")  # stores unchanged area ids (don't change with highlights)
@onready var green_cell: Vector2i = Vector2i(0, 1)  # atlas coords for default territory cell (green)
@onready var gray_cell: Vector2i = Vector2i(0, 0)  # base cell used for alt (the grayscale one)
@onready var initial_tile_map_data = []  # store original tilemap data
@onready var placement_preview = $PlacePreview

# piece drawing
var player_piece_scale: Vector2 = Vector2(1.2, 1.2)
var piece_offset = Vector2(15, 0)
var player_piece_offset = Vector2(0, 30)

# drawing state for placement
var last_hovered_territory: int = -1


func _ready() -> void:
	
	# get tile map data for restoration
	self.initial_tile_map_data = tilemap.get_tile_map_data_as_array()
	
	show_territory_points()
	
	update_piece_drawing_params_based_on_num_players()
	
	# connect signal to redraw once game state is updated
	GameState.deploy_state_updated.connect(_on_deploy_state_updated)

	# on dice results, highlight valid territories
	control_scene.dice_rolled.connect(_on_dice_rolled)
	
	# on dice selection, unhighlight all territories
	control_scene.dice_selected.connect(_on_dice_selected)
	
	# on card moves, highlight valid territories
	control_scene.card_selected.connect(_on_card_selected)
	game_scene.card_revert_move_deployed.connect(_on_card_revert_move_deployed)
	board_scene.card_target_selection_requested.connect(_on_card_target_selection_requested)
	board_scene.leader_target_selection_requested.connect(_on_leader_target_selection_requested)
	board_scene.card_effect_incremented.connect(_on_card_effect_incremented)
	
	# on game scored, redraw sprites and highlight territory by winning player
	game_scene.game_scored.connect(_on_game_scored)


func _physics_process(delta: float) -> void:
	
	hide_placement_popup()
	
	# if in reroll or place phase (ie we have dice results)
	if (
		GameState.current_phase == GameState.TurnPhase.REROLL or
		GameState.current_phase == GameState.TurnPhase.PLACE
	):
		if GameState.current_dice != []:
			# detect mouse hovering
			var cell = tilemap_constant.local_to_map(tilemap_constant.get_local_mouse_position())
			var data = tilemap_constant.get_cell_tile_data(cell)
			var tile_id = -1
			if data:
				tile_id = data.get_custom_data("area_id")
			
			# see if hovered over area is a valid area in current dice combo
			# move options is an array of dictionaries
			var move_options = Helper.combine_dice(GameState.current_dice)
			for move_option in move_options:
				if tile_id == move_option["territory_index"]:
					show_placement_popup(tile_id, move_option)


func _input(event):
	# on clicking the cell, emit signal on which territory is clicked and mouse position
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = tilemap_constant.local_to_map(tilemap_constant.get_local_mouse_position())
		var data = tilemap_constant.get_cell_tile_data(clicked_cell)
		var tile_id = -1
		if data:
			tile_id = data.get_custom_data("area_id")
		
		if tile_id != -1:
			territory_clicked.emit(tile_id, event.global_position)


func show_territory_points():
	"""Populate points label."""
	var i: int = 0
	for territory: Node2D in self.territory_nodes.get_children():
		var points = GameState.board_state["territory_points"][i]
		territory.set("territory_index", i)
		territory.set("territory_points", points)
		territory.get_node("Points/Label").set_text(str(points))
		i += 1


func update_piece_drawing_params_based_on_num_players():
	"""Update how big the pieces should be based on number of players."""
	match GameState.num_players:
		2: self.player_piece_scale = Vector2(1.2, 1.2)
		3: self.player_piece_scale = Vector2(1.2, 1.2)
		4: self.player_piece_scale = Vector2(1, 1)


func highlight_territories(territories: Array, player: int):
	"""Highlight territories given indices and player (used to fetch highlight color tile)."""
	# to highlight, we replace all cells in a territory with an alt cell
	for territory in territories:
		# source = 0, atlas_coords = default cell, alternative = 1-11, which is territory index +1
		var area_cells = self.tilemap.get_used_cells_by_id(0, green_cell, territory + 1)
		for cell in area_cells:
			self.tilemap.set_cell(cell, 0, gray_cell, GameState.players[player]["alt_atlas_id"])


func unhighlight_territories():
	"""Unhighlight all territories."""
	# simply restore to original tilemap data
	tilemap.set_tile_map_data_from_array(self.initial_tile_map_data)


func draw_piece_sprites():
	"""Redraw all deployments based on territory_tally.
	Redrawing all is beneficial due to resets and reverts."""
	
	var territory_index: int = 0
	for territory: Node2D in self.territory_nodes.get_children():
		var piece_container = territory.get_node("PieceContainer")
		
		# clear existing pieces if any:
		for piece in piece_container.get_children():
			piece.queue_free()
	
		# first draw soldiers
		for player in range(GameState.num_players):
			
			var icon = GameState.players[player]["icon"]
			var icon_leader = GameState.players[player]["icon_leader"]
			var icon_reinforcement = GameState.players[player]["icon_reinforce"]
			
			var territory_tally = GameState.board_state["territory_tally"][territory_index]
			
			# draw leader in the front if there is a leader
			if territory_tally[player]["leader"] > 0:
				var leader_sprite = Sprite2D.new()
				leader_sprite.scale = player_piece_scale * 1.5
				leader_sprite.texture = icon_leader
				# if player 1 and 4 have pieces, don't have 2 blank lines in between
				var players_on_territory = TerritoryHelper.get_players_on_territory(territory_index)
				var num_vertical_offsets = players_on_territory.find(player)
				leader_sprite.position = num_vertical_offsets * player_piece_offset
				piece_container.add_child(leader_sprite)
			
			# draw soldiers
			for i in range(territory_tally[player]["soldier"]):
				var piece_sprite = Sprite2D.new()
				piece_sprite.scale = self.player_piece_scale
				piece_sprite.texture = icon
				# leave space for leader, hence (i + 1)
				var players_on_territory = TerritoryHelper.get_players_on_territory(territory_index)
				var num_vertical_offsets = Vector2(0, players_on_territory.find(player))
				# only leave leader space if there is a leader
				piece_sprite.position += (i + 2 * territory_tally[player]["leader"]) * piece_offset
				piece_sprite.position += num_vertical_offsets * player_piece_offset
				piece_container.add_child(piece_sprite)

			
			# draw reinforcements
			if territory_tally[player]["reinforcement"] > 0:
				for i in range(territory_tally[player]["reinforcement"]):
					var reinforce_sprite = Sprite2D.new()
					reinforce_sprite.scale = player_piece_scale * 0.5
					reinforce_sprite.texture = icon_reinforcement
					var players_on_territory = TerritoryHelper.get_players_on_territory(territory_index)
					var num_vertical_offsets = players_on_territory.find(player)
					reinforce_sprite.position += (territory_tally[player]["soldier"] + 2 * territory_tally[player]["leader"]) * piece_offset
					reinforce_sprite.position += i * piece_offset * 0.5
					reinforce_sprite.position += num_vertical_offsets * player_piece_offset
					piece_container.add_child(reinforce_sprite)
		
		territory_index += 1


func _on_dice_rolled(dice_results: Array, move_options: Array):
	"""Highlight territories on dice rolled."""
	unhighlight_territories()
	
	var territories_to_highlight = []
	for option: Dictionary in move_options:
		territories_to_highlight.append(option["territory_index"])
	
	highlight_territories(territories_to_highlight, GameState.current_player)


func _on_dice_selected(territory_index: int, deploy_count: int, has_leader: bool):
	"""Unhighlight all territories."""
	unhighlight_territories()


func _on_deploy_state_updated():
	draw_piece_sprites()


func _on_card_selected(card: Card):
	# highlight which territories are eligible when a card is selected (1st move)
	print(card.effect_index)
	var territories = card.get_card_step_territories(card.effect_index)
	print(territories)
	highlight_territories(territories, GameState.current_player)


func _on_card_revert_move_deployed():
	# revert is like reselecting the card
	_on_card_selected(GameState.current_card)


func show_placement_popup(territory: int, move_option: Dictionary):
	# clear existing pieces
	for piece in self.placement_preview.get_children():
		piece.queue_free()
		
	self.placement_preview.show()
	
	# update the numbers shown (if first time)
	if self.placement_preview.move_to_display["num_soldiers"] == -1:
		self.placement_preview.update_move(move_option["deploy_count"], false)
	
	# if changing tiles
	if territory != self.last_hovered_territory:
		# keep the leader, ie if leader is toggled on, keep on
		if self.placement_preview.move_to_display["has_leader"]:
			# only when leader is available (inbetween turns)
			if GameState.players[GameState.current_player]["leader"] >= 0:
				self.placement_preview.update_move(move_option["deploy_count"] - 1, true)
			else:
				self.placement_preview.update_move(move_option["deploy_count"], false)
		else:
			self.placement_preview.update_move(move_option["deploy_count"], false)
				
		self.last_hovered_territory = territory
	
	self.placement_preview.draw_pieces()
	
	# follow the mouse
	self.placement_preview.global_position = get_viewport().get_mouse_position() + Vector2(10, 0)


func hide_placement_popup():
	self.placement_preview.hide()


func show_target_selection_popup(mouse_position: Vector2, valid_opponents: Array, territory_clicked: int):
	# clean up if needed
	if has_node("PopUp"):
		$PopUp.queue_free()
	
	# inistantiate the popup
	var target_selection_popup = preload("res://popup.tscn").instantiate()
	
	# generate options per valid opponents
	for valid_opponent in valid_opponents:
		var opponent_name = GameState.players[valid_opponent]["name"]
		var target_button = Button.new()
		target_button.text = opponent_name
		target_button.icon = GameState.players[valid_opponent]["icon"]
		target_button.name = "Player" +  str(valid_opponent)
		
		# connect button to pressed signal
		target_button.pressed.connect(_on_target_selected.bind(valid_opponent, territory_clicked))
		
		# add the buttons to pop up menu
		target_selection_popup.get_node("PopupPanel/VBoxContainer").add_child(target_button)
	
	# add pop up to scene tree
	add_child(target_selection_popup)
	target_selection_popup.get_node("PopupPanel").popup()
	target_selection_popup.get_node("PopupPanel").position = mouse_position


func show_leader_selection_window(mouse_position: Vector2, territory_clicked: int):
	# clean up if needed
	if has_node("PopUp"):
		$PopUp.queue_free()
	
	# inistantiate the popup
	var current_player = GameState.current_player
	var target_selection_popup = preload("res://popup.tscn").instantiate()
	
	for i in range(2):
		var button = Button.new()
		button.text = ["Apply to Soldiers Only", "Apply to Leader"][i]
		button.icon = GameState.players[current_player][["icon", "icon_leader"][i]]
	
		# connect button to pressed signal, 0=false=do not apply to leader
		button.pressed.connect(_on_apply_to_leader_selected.bind(bool(i), territory_clicked))
	
		# add the buttons to pop up menu
		target_selection_popup.get_node("PopupPanel/VBoxContainer").add_child(button)

	# add pop up to scene tree
	add_child(target_selection_popup)
	target_selection_popup.get_node("PopupPanel").popup()
	target_selection_popup.get_node("PopupPanel").position = mouse_position


func _on_card_target_selection_requested(mouse_position: Vector2, valid_opponents: Array, territory_clicked: int):
	show_target_selection_popup(mouse_position, valid_opponents, territory_clicked)


func _on_leader_target_selection_requested(mouse_position: Vector2, territory_clicked: int):
	show_leader_selection_window(mouse_position, territory_clicked)


func _on_apply_to_leader_selected(apply_to_leader: bool, territory_clicked: int):
	if has_node("PopUp"):
		$PopUp.queue_free()
	leader_target_selected.emit(apply_to_leader, territory_clicked)


func _on_card_effect_incremented(card: Card):
	# unhighlight existing territories (if any) and highlight next step territories
	unhighlight_territories()
	if card.effect_index < card.effect.size():
		highlight_territories(
			card.get_card_step_territories(card.effect_index), GameState.current_player
		)


func _on_target_selected(selected_opponent: int, territory_clicked: int):
	target_selected.emit(selected_opponent, territory_clicked)


func _on_territory_clicked(territory: int, mouse_position: Vector2):
	# unhiglight all territories
	unhighlight_territories()


func _on_game_scored():
	# draw reinforcements
	draw_piece_sprites()
	
	# color territories by winning player
	for territory in range(GameState.num_territories):
		if GameState.board_state["territory_winner"][territory] != -1:
			highlight_territories(
				[territory],
				GameState.board_state["territory_winner"][territory],
			)
