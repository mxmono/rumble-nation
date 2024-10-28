extends Node2D

# a list of territory Area2D's ordered by assigned points, ie the 1st territory has 2 points
@export var territories = []
# a list of territory Area2D's in their original orders (ie territory1, territory2, ...)
@export var territories_default = []
@export var territory_connections = [
	{"land": [], "water": [2, 3, 4]},
	{"land": [], "water": [1, 4, 5]},
	{"land": [], "water": [1]},
	{"land": [5], "water": [1, 2]},
	{"land": [4, 6, 7], "water": [2]},
	{"land": [5, 7, 8], "water": []},
	{"land": [5, 6, 8, 10], "water": []},
	{"land": [6, 7, 9, 10], "water": []},
	{"land": [8, 10], "water": [11]},
	{"land": [7, 8, 9], "water": []},
	{"land": [], "water": [9]},
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for territory in $Map.get_children():
		if territory.has_method("connect"):
			territory.connect("territory_clicked", Callable(self, "_on_territory_clicked"))
		territories_default.append(territory)
	assign_points_to_territories()

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

# Respond to territory clicks
func _on_territory_clicked(territory_name):
	print("Territory clicked: ", territory_name)
	# Add game logic here, such as handling player interactions, turns, etc.

# Handle the piece being placed on a territory
func _on_piece_placed(piece):
	print("Piece placed: ", piece.name)
	# Add logic to handle turns, scoring, or ownership changes
