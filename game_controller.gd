extends Node

@export var player_priority = []  # store which players are out first

@onready var dice_buttons = $Control/GameButtons/Dice.get_children()
@onready var card_buttons = $Control/GameButtons/Card/CardTray.get_children() + $Control/GameButtons/Leader/CardTray.get_children()
@onready var card_action_buttons = $Control/GameButtons/Card/ActionButtons.get_children() + $Control/GameButtons/Leader/ActionButtons.get_children()
const DICE_MENU_PARENT = "Control/GameButtons/Dice/"
const CARD_MENU_PARENT = "Control/GameButtons/Card/"
const LEADER_MENU_PARENT = "Control/GameButtons/Leader/"
@onready var pause_menu = $MenuCanvas/PauseMenu


func _ready():
	var board_scene = get_node("/root/GameController/Map")
	board_scene.card_move_selected.connect(_on_card_move_selected)
	board_scene.card_move_reverted.connect(_on_card_move_reverted)
	
	# connect signals
	var control_scene = get_node("/root/GameController/Control")
	control_scene.roll_phase_done.connect(_on_place_phase_done)
	$Control/GameButtons/Card/ActionButtons/ConfirmCardButton.pressed.connect(_on_card_confirmed)
	$Control/GameButtons/Leader/ActionButtons/ConfirmCardButton.pressed.connect(_on_card_confirmed)
	
	for card_button in card_buttons:
		card_button.card_selected.connect(_on_card_selected)
	
	# start turn sequence
	start_turn()

func _process(delta):
	self.card_buttons = $Control/GameButtons/Card/CardTray.get_children()
	self.card_buttons += $Control/GameButtons/Leader/CardTray.get_children()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false  # Resume the game
		pause_menu.hide()  # Hide the pause menu
	else:
		get_tree().paused = true  # Pause the game
		pause_menu.show()  # Show the pause menu centered

func start_turn():
	if all_players_out():
		print("All players are out of pieces! Transitioning to scoring phase.")
		scoring_phase()
		return
	
	# Find the next active player with pieces
	while not GameState.players[GameState.current_player]["active"]:
		GameState.current_player = (GameState.current_player + 1) % GameState.num_players

	print(GameState.players[GameState.current_player]["name"], "'s turn.")
	update_stats_label()
	
	# UI: enable all relevant buttons and labels
	for card_button in self.card_buttons:
		card_button.disabled = not card_button.is_condition_met(GameState.current_player)
	for card_action_button in card_action_buttons:
		card_action_button.disabled = true
		# hide finish move, only show it when it's relevant for a card
		if card_action_button.name == "FinishCardMoveButton":
			card_action_button.visible = false

	for dice_button in self.dice_buttons:
		if dice_button is Button:
			if dice_button.name == "RollDiceButton":
				dice_button.disabled = false
				dice_button.visible = true
	get_node(DICE_MENU_PARENT + "ResultLabel").text = ""

	# UI: if any player is out, cannot use card any more
	for player in range(GameState.num_players):
		if not GameState.players[player]["active"]:
			for card_button in self.card_buttons + self.card_action_buttons:
				card_button.disabled = true
			
	# UI: use player color as menu background color
	var current_color = GameState.players[GameState.current_player]["color"]
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = current_color
	style_box.bg_color.a = 0.2
	$Control/GameButtons.add_theme_stylebox_override("panel", style_box)

	GameState.current_phase = GameState.TurnPhase.CHOICE
	process_turn_phase()

func update_stats_label():
	if all_players_out():
		$Info/PlayerLabel.text = "All players out"
	else:
		$Info/PlayerLabel.text = "%s's Turn" % GameState.players[GameState.current_player]["name"]
	for i in range(GameState.num_players):
		$Info/PlayerLabel.text += "\n%s: %s soldier(s) left; %s leader left" % [
			GameState.players[i]["name"],
			str(GameState.players[i]["soldier"]),
			str(GameState.players[i]["leader"])
		]

# Check if all players are out of pieces
func all_players_out() -> bool:
	for player in GameState.players:
		if player["active"]:
			return false  # At least one player still has pieces
	return true  # All players are out of pieces

func process_turn_phase():
	var current_player_name = GameState.players[GameState.current_player]["name"]
	match GameState.current_phase:

		GameState.TurnPhase.CHOICE:
			print(current_player_name, " is in the CHOICE phase.")

		GameState.TurnPhase.CARD:
			print(current_player_name, " is in the CARD phase.")
			card_phase()

		GameState.TurnPhase.CONFIRM_OR_RESET_CARD:
			print(current_player_name, " to confirm or reset CARD actions.")
			comfirm_or_reset_card_phase()
		
		GameState.TurnPhase.ROLL:
			print(current_player_name, " is in the ROLL phase.")
			roll_phase()
		
		GameState.TurnPhase.REROLL:
			print(current_player_name, " is in the REROLL phase.")
			reroll_phase()
		
		GameState.TurnPhase.PLACE:
			print(current_player_name, " is in the PLACE phase.")
			place_phase()

		GameState.TurnPhase.END:
			print(current_player_name, "'s turn is ending.")
			end_turn()

#region handles card selection and application actions
func card_phase():
	# UI: disable all buttons in dice menu
	for dice_button in self.dice_buttons:
		if dice_button is Button:
			dice_button.visible = false
			dice_button.disabled = true
		else:  # it's the label
			dice_button.text = "Cannot use dice, a card has been selected"
			
	# UI: disable confirm or reset buttons
	get_node(CARD_MENU_PARENT + "ActionButtons/ConfirmCardButton").disabled = true
	get_node(CARD_MENU_PARENT + "ActionButtons/ResetCardButton").disabled = true
	get_node(LEADER_MENU_PARENT + "ActionButtons/ConfirmCardButton").disabled = true
	get_node(LEADER_MENU_PARENT + "ActionButtons/ResetCardButton").disabled = true

func comfirm_or_reset_card_phase():
	# UI: enable confirm or reset buttons
	get_node(CARD_MENU_PARENT + "ActionButtons/ConfirmCardButton").disabled = false
	get_node(CARD_MENU_PARENT + "ActionButtons/ResetCardButton").disabled = false
	get_node(LEADER_MENU_PARENT + "ActionButtons/ConfirmCardButton").disabled = false
	get_node(LEADER_MENU_PARENT + "ActionButtons/ResetCardButton").disabled = false

func _on_card_selected(card):
	# when clicked on a card, user has made a choice, ending the choice phase
	GameState.current_phase = GameState.TurnPhase.CARD
	process_turn_phase()
	
	# when player clicks on a playable card in the card tray
	# make sure globally we know which card is being player
	GameState.current_card = card
	
	# UI: highlight the selected card
	card.modulate = GameState.players[GameState.current_player]["color"]
	
	# UI: disable all card buttons
	for card_button in card_buttons:
		card_button.disabled = true

func _on_card_move_selected(moves):
	# moves is an array of [[player, territory_index, deploy_count, has_leader]]
	# when player clicked on territories to apply effect of the card
	# proceed to confirm or reset card
	# only do so if the card effect has fully finished, as signal can be emitted for multi-step midway
	if GameState.current_card.effect_index == GameState.current_card.effect.size():
		GameState.current_phase = GameState.TurnPhase.CONFIRM_OR_RESET_CARD
		process_turn_phase()

func _on_card_move_reverted(moves):
	# go back to CARD phase where user needs to take actions to apply effect of card
	GameState.current_phase = GameState.TurnPhase.CARD
	process_turn_phase()
	
func _on_card_confirmed():
	# the used card disappears
	GameState.current_card.queue_free()
	
	# mark player
	GameState.players[GameState.current_player]["used_card"] = true
	
	# once the player confirmed the card action, transition to next turn
	GameState.current_phase = GameState.TurnPhase.END
	process_turn_phase()

	# reset for next card play
	GameState.current_card = null
#endregion

#region handles dice rolling and piece placement actions
func roll_phase():
	print(GameState.players[GameState.current_player]["name"], " rolls.")

func reroll_phase():
	get_node(DICE_MENU_PARENT + "RollDiceButton").text = "Reroll"
	
func _on_dice_rolled(dice_results, move_options):
	# allow reroll if current player has used a card, otherwise the turn ends
	if GameState.players[GameState.current_player]["used_card"]:
		if GameState.current_phase != GameState.TurnPhase.REROLL:
			GameState.current_phase = GameState.TurnPhase.REROLL
		else:  # already rerolled
			GameState.current_phase = GameState.TurnPhase.PLACE
	else:
		GameState.current_phase = GameState.TurnPhase.PLACE
	process_turn_phase()
	
	# disable all card actions in card menu:
	for card_button in self.card_buttons + self.card_action_buttons:
		card_button.disabled = true

func place_phase():
	get_node(DICE_MENU_PARENT + "RollDiceButton").disabled = true
	
func _on_place_phase_done():
	# UI: disable buttons
	for button in self.dice_buttons:
		if button is Button and button.name.begins_with("DiceOption"):
			button.visible = false
			button.disabled = true
		if button.name == "RollDiceButton":
			button.disabled = true
			button.text = "Roll Dice"
			

	GameState.current_phase = GameState.TurnPhase.END
	process_turn_phase()
#endregion 

# Ends the player's turn and switches to the next player
func end_turn():
	print(GameState.players[GameState.current_player]["name"], "'s turn is over.")
	# unhighlight territories
	$Map.unhighlight_territories($Map.territory_index_to_points.keys())
	
	# Update player pieces and check if they are out
	if GameState.players[GameState.current_player]["leader"] + GameState.players[GameState.current_player]["soldier"] <= 0:
		print(GameState.players[GameState.current_player]["name"], " is out of pieces!")
		GameState.players[GameState.current_player]["active"] = false
		# store player out sequence for tie-breaker
		player_priority.append(GameState.current_player)

	# Switch to the next player
	GameState.current_player = (GameState.current_player + 1) % GameState.num_players
	update_stats_label()

	# Start the next player's turn
	start_turn()

func scoring_phase():
	print("entering scoring phase")
	# UI: disable the buttons
	for dice_button in self.dice_buttons:
		if dice_button is Button:
			dice_button.disabled = true
		if dice_button is Label:
			dice_button.text = ""
	for card_button in self.card_buttons + self.card_action_buttons:
		if card_button is Button:
			card_button.disabled = true
	
	# logic for scoring
	var territories = get_node("/root/GameController/Map").territories

	for territory in territories:
		# check who wins
		var territory_tally = GameState.board_state["territory_tally"][territory.territory_index]
		var scores = []
		for player_tally in territory_tally:
			scores.append(
				player_tally["soldier"] + player_tally["reinforcement"] + player_tally["leader"] * 2
			)
		var win_order_players =  get_player_win_order(scores, player_priority)
		var first_place_player = -1
		var second_place_player = -1
		if win_order_players.size() >= 1:
			first_place_player = win_order_players[0]
			if win_order_players.size() > 1:
				second_place_player = win_order_players[1]

		# TODO: set territory color to winning player color
		var visual_polygon = territory.get_node("Polygon2D")
		if first_place_player != -1:
			var highlight_material = CanvasItemMaterial.new()
			highlight_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			visual_polygon.material = highlight_material
			visual_polygon.color = GameState.players[first_place_player]["color"]
		
		if first_place_player == -1:  # if no one wins, go to next territory
			continue
		
		print(
			territory.territory_points, ":  ", GameState.players[first_place_player]["name"], " wins",
			"  credited ", territory.territory_points, "  to ", GameState.players[first_place_player]["name"]
		)
		if second_place_player != -1:
			print(
				GameState.players[second_place_player]["name"], " is second place",
			)
		
		# reinforce to adjacent territories
		territory.reinforce(GameState.num_players, first_place_player)
		
		# credit score to the player
		GameState.players[first_place_player]["score"] += territory.territory_points
		
		# add half score (round down) to 2nd place if more than 2 players
		if GameState.num_players > 2:
			if second_place_player != -1:
				GameState.players[second_place_player]["score"] += territory.territory_points / 2
				print("credited ", territory.territory_points / 2, " to ", GameState.players[second_place_player]["name"])

	# annouce the winner
	var current_max = 0
	var winner = -1
	var current_max_player_priority = -1
	for player in range(GameState.num_players):
		
		if GameState.players[player]["score"] > current_max:
			current_max = GameState.players[player]["score"]
			winner = player
			current_max_player_priority = self.player_priority.find(player)
		
		# if tie, the player goes out first wins
		elif GameState.players[player]["score"] == current_max:
			var player_priority = self.player_priority.find(player)
			if player_priority < current_max_player_priority:
				winner = player
	
	# UI: update winding label
	$Info/PlayerLabel.text = "%s wins!" % GameState.players[winner]["name"]
	var player_priority_name = []
	for player in player_priority:
		player_priority_name.append(GameState.players[player]["name"])
	$Info/PlayerLabel.text += " Out sequence: %s" % str(player_priority_name)
	for i in range(GameState.num_players):
		$Info/PlayerLabel.text += "\n%s: %s" % [GameState.players[i]["name"], GameState.players[i]["score"]]

func get_winning_player(scores: Array, player_priority) -> int:
	"""Based on total score and out sequence (player priority), return winning player"""
	var max_value = scores.max()  # Find the maximum value in the array

	# no one wins if no pieces
	if max_value <= 0:
		return -1
	var player_index = []  # Array to store the indices of the max value
	
	# Loop through the array to find players with the highest score
	for i in range(scores.size()):
		if scores[i] == max_value:
			player_index.append(i)
	
	# if tie, check which player is out first, eg players [1, 2] tie
	# then if the player priority is [2, 1], player 2 wins
	if player_index.size() > 1:
		for player in player_priority:
			if player_index.find(player) != -1:
				return player
	
	# otherwise if only 1 winner, return the winner
	return player_index[0]

func get_player_win_order(scores: Array, player_priority: Array) -> Array:
	"""Return an array of win order, eg [2, 3, 0, 1], player 2 is first place."""
	
	var win_order_players = []  # if there are only 1 player on tile, should only have 1 element
	var num_players_with_scores = 0
	for score in scores:
		if score > 0:
			num_players_with_scores += 1
	
	for i in range(num_players_with_scores):
		var winning_player = get_winning_player(scores, player_priority)
		win_order_players.append(winning_player)
		# set the score of the already identified player to -1
		scores[winning_player] = -1

	return win_order_players
