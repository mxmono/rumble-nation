extends Node2D

@onready var tilemap = $TerrainPattern  # Assuming your TileMap node is named TileMap

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var clicked_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
		var data = tilemap.get_cell_tile_data(clicked_cell)
		var tile_id = -1
		if data:
			tile_id = data.get_custom_data("area_id")

		if tile_id != -1:
			var area_name = get_area_name_from_tile(tile_id)
			print("Clicked on area: ", area_name)
			#highlight_area(clicked_cell)
			var used_tile = $TerrainPattern.get_cell_atlas_coords(clicked_cell)
			var area_cells = $TerrainPattern.get_used_cells_by_id(0, used_tile, tile_id+1)
			for cell in area_cells:
				$TerrainPattern.set_cell(cell, 0, Vector2i(15, 6), 0)
		else:
			print("Clicked on an empty space.")

# Function to map tile IDs to area names
func get_area_name_from_tile(tile_id: int) -> String:
	match tile_id:
		0: return "Territory 0"
		1: return "Territory 1"
		2: return "Territory 2"
		3: return "Territory 3"
		4: return "Territory 4"
		5: return "Territory 5"
		6: return "Territory 6"
		7: return "Territory 7"
		8: return "Territory 8"
		9: return "Territory 9"
		10: return "Territory 10"
		_ : return "Unknown Area"

func highlight_area(clicked_cell):
	$TerrainPattern.set_cell(clicked_cell, 0, Vector2i(15, 6), 0)
