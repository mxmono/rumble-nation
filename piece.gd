extends Node2D

# Signal emitted when the piece is placed on a territory
signal piece_dropped(piece, territory)

# Preload the Piece scene
var piece_scene: PackedScene = load("res://piece.tscn")
# Variables to control dragging behavior
var is_dragging = false
var original_position: Vector2
var drag_offset: Vector2

const PIECE_INIT_POSITION = Vector2(1130, 0)

# Called when the node is ready
func _ready():
	# Remember the original position in case the piece is not dropped on a valid territory
	global_position = PIECE_INIT_POSITION
	original_position = position

	# Connect the input event for dragging the piece
	$Area2D.input_event.connect(_on_input_event)

# Handles input for dragging and dropping the piece
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Calculate the offset between the mouse position and the piece position when dragging starts
			drag_offset = global_position - get_global_mouse_position()
			is_dragging = true
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# Stop dragging when the mouse button is released
			is_dragging = false
			_drop_piece()

# Handle dragging
func _process(delta):
	if is_dragging:
		# Move the piece to follow the mouse cursor while dragging
		global_position = get_global_mouse_position() + drag_offset

# Handles dropping the piece
func _drop_piece():
	# Create a PhysicsPointQueryParameters2D object
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()  # Set the position to the mouse position
	query.collide_with_areas = true  # Ensure it checks for Area2D collisions

	# Perform the query
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_point(query)

	if result.size() > 0:
		var territory = result[0].collider.get_parent()  # Get the first collider in the result
		if territory.has_method("place_piece"):
			# Snap the piece to the territory's position
			global_position = get_global_mouse_position() + drag_offset
			territory.place_piece(self)
			# Generate the next piece
			_generate_next_piece()
			# Emit a signal indicating the piece was dropped on a territory
			piece_dropped.emit(self, territory)
		else:
			# Reset to original position if not dropped on a valid territory
			position = original_position
	else:
		# Reset to original position if dropped in an invalid location
		position = original_position

# Function to generate the next piece
func _generate_next_piece():
	# Instance a new piece from the packed scene
	var new_piece = piece_scene.instantiate()
	# Add the new piece to the same parent node (or anywhere appropriate)
	get_parent().add_child(new_piece)
	# Set the position for the new piece (e.g., at the starting point of the board)
	new_piece.global_position = original_position
	print("New piece generated and placed at the start.")
