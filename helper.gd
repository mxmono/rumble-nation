extends Node


func get_array_overlap(arr1: Array, arr2: Array) -> Array:
	"""Get overlap elements of two arrays."""
	
	var arr = []
	for item in arr1:
		if arr2.has(item):
			if not arr.has(item):
				arr.append(item)
	
	return arr


func union_set(arr1: Array, arr2: Array) -> Array:
	"""Get unique items from both arrays."""
	
	var arr = []
	for item in arr1 + arr2:
		if not arr.has(item):
			arr.append(item)
	
	return arr


func get_sort_order_descending(arr: Array) -> Array:
	"""Get sort order of an array."""
	
	var array = arr.duplicate()
	var current_max = array.max()
	var sort_order = []
	while array.size() > 0:
		sort_order.append(arr.find(current_max))
		array.erase(current_max)
		current_max = array.max()
	
	return sort_order


func combine_dice(dice_results: Array) -> Array:
	"""Combine three dice results into move options."""
	var current_player = GameState.current_player
	var territory_points = GameState.board_state["territory_points"]
	
	# calculate all move options
	var move_options = []
	for i in range(3):
		# deploy count is bound by how many pieces are left
		var deploy_count = (dice_results[i % 3] + 1) / 2
		deploy_count = min(
			deploy_count,
			GameState.players[current_player]["soldier"] + GameState.players[current_player]["leader"]
		)
		var territory_score = dice_results[(i + 1) % 3] + dice_results[(i + 2) % 3]
		var territory_index = territory_points.find(territory_score)
		var option = {
			"deploy_count": deploy_count,
			"territory_score": territory_score, 
			"territory_index": territory_index
		}
		# only add if the move is not repeated
		if not move_options.has(option):
			move_options.append(option)

	return move_options
