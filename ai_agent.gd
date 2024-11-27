extends Node

@onready var game_logic = get_node("/root/Game")
@onready var control_scene = get_node("/root/Game/Control")

var ai_timer: float = 1
# probability of going for a tile if the tile is empty
const EMPTY_TILE_PROB = {
	2:10,
	3:8,
	4:6,
	5:3,
	6:2,
	7:2,
	8:3,
	9:6,
	10:8,
	11:10,
	12:10,
}


func _ready() -> void:
	game_logic.phase_started.connect(_on_phase_started)


func _on_phase_started(phase):
	# agento to react with actions when it's there turn
		
		if not GameState.players[GameState.current_player]["is_ai"]:
			return 
		
		match phase:

			GameState.TurnPhase.CHOICE:
					
					# timer delay, also needed to make sure signal receipt order is correct
					await get_tree().create_timer(ai_timer).timeout
					
					control_scene.click_roll_dice()
				
			GameState.TurnPhase.PLACE:
				
				await get_tree().create_timer(ai_timer).timeout
				
				var moves = Helper.combine_dice(GameState.current_dice)
				
				randomize()
				var i = -1
				if randf() < 0.8:
					i = select_empty(moves)
				if i == -1:
					if randf() < 0.8:
						i = select_score_max(moves)
					else:
						i = select_random(moves)
				
				var has_leader = is_playing_leader()

				control_scene.select_dice_option(i, has_leader)


func select_empty(moves: Array) -> int:
	"""Pick a territory that's empty based on defined probabilities. Retuns option index."""
	
	# putting balls into a draw pool, eg ball-2 10 times, ball-3 5 times, and draw a ball
	# we are drawing the option instead of the ball (territory index) itself
	# eg if option 1 of moves is (place x on 2) - 10 balls, option 2 is (place y on 3) - 5 balls
	# we have an array with 10 0's and 5 1's, and draw an option index
	var option_draw_pool = []
	
	for i in range(moves.size()):
		var move_territory: int = moves[i]["territory_index"]
		var move_territory_points: int = moves[i]["territory_score"]
		if TerritoryHelper.is_territory_empty(move_territory):
			var new_entry = []
			new_entry.resize(EMPTY_TILE_PROB[move_territory_points])
			new_entry.fill(i)
			option_draw_pool += new_entry
	
	# if no territory is empty, returns -1
	if option_draw_pool.is_empty():
		return -1
	
	randomize()
	
	return option_draw_pool.pick_random()


func select_random(moves: Array) -> int:
	"""Select a random option. Returns option index."""
	randomize()
	return randi_range(0, moves.size() - 1)


func select_score_max(moves: Array) -> int:
	"""Select the move that gives the max score IF game resolves after the move."""
	
	var resolved_scores = []
	
	for move in moves:
		
		# update the gamestate with the potential move
		GameState.update_game_state_on_deployed(
			GameState.current_player, move["territory_index"], move["deploy_count"], false, false
		)
		
		# get current player priority based on how many pieces are left
		var player_pieces_left = []
		for player in GameState.players:
			player_pieces_left.append(player["soldier"] + player["leader"])
		
		var current_priority = Helper.get_sort_order_descending(player_pieces_left)
		current_priority.reverse()  # least pieces = first out

		var player_scores = game_logic.resolve_game(current_priority)
		
		resolved_scores.append(player_scores[GameState.current_player])
		
		# make sure to reset game state
		game_logic.reset_game_state_post_adhoc_resolution()
		GameState.update_game_state_on_deployed(
			GameState.current_player, move["territory_index"], -move["deploy_count"], false, false
		)
	
	var max_score = resolved_scores.max()
	
	return resolved_scores.find(max_score)
	
	
func is_playing_leader() -> bool:
	"""Decide if playing leader."""
	
	var has_leader = false
	if GameState.players[GameState.current_player]["leader"] > 0:
		has_leader = bool(randf() < 0.2) 
		if GameState.players[GameState.current_player]["soldier"] <=3:
			has_leader = true
	
	return has_leader
