extends Node

var num_players: int = 2
var total_soldiers: int = 16
var num_territories: int = 11
var current_player: int = 0
var current_card = null
enum TurnPhase {
	CHOICE,
	CARD,
	CONFIRM_OR_RESET_CARD,
	ROLL,
	REROLL,
	PLACE,
	END
}
var current_phase = TurnPhase.CHOICE
var player_presets = [
	{
		"name": "Reddo",
		"icon": preload("res://icons/char1.png"),
		"leader": preload("res://icons/lead1.png"),
		"reinforce":  preload("res://icons/reinforce1.png"),
		"color": Color(1, 0, 0),
	},
	{
		"name": "Blu",
		"icon": preload("res://icons/char2.png"),
		"leader": preload("res://icons/lead2.png"),
		"reinforce":  preload("res://icons/reinforce2.png"),
		"color": Color(0, 0.58, 0.71)
	},
	{
		"name": "Yello",
		"icon": preload("res://icons/char3.png"),
		"leader": preload("res://icons/lead3.png"),
		"reinforce":  preload("res://icons/reinforce3.png"),
		"color": Color(0.79, 0.49, 0.24)
	},
	{
		"name": "Greeny",
		"icon": preload("res://icons/char4.png"),
		"leader": preload("res://icons/lead4.png"),
		"reinforce":  preload("res://icons/reinforce4.png"),
		"color": Color(0, 0.57, 0.53)
	},
]

# array of players, each element is a dictionary, eg
# [
#   {"name": "player 0", "solider": 12, ...}
#   {"name": "player 1", "solider": 12, ...}
# ]
var players = []
# territroy tally: array of territories, each element is an array of player stats on territory, eg
# [ 
#   [ {"soldier": 0, "leader": 0}, {"soldier": 0, "leader": 0} ], # territory index 0,
#   [ {"soldier": 0, "leader": 0}, {"soldier": 0, "leader": 0} ], # territory index 1,
# ]
var board_state = {
	"territory_points": [],
	"territory_tally": [],
	"territory_connections": [
		{"land": [], "water": [1, 2, 3]},		# 0
		{"land": [], "water": [0, 3, 4]},		# 1
		{"land": [], "water": [0]},				# 2
		{"land": [4], "water": [0, 1]},			# 3
		{"land": [3, 5, 6], "water": [1]},		# 4
		{"land": [4, 6, 7], "water": []},		# 5
		{"land": [4, 5, 7, 9], "water": []},	# 6
		{"land": [5, 6, 8, 9], "water": []},	# 7
		{"land": [7, 9], "water": [10]},		# 8
		{"land": [6, 7, 8], "water": []},		# 9
		{"land": [], "water": [8]},				# 10
	]
}


func _ready() -> void:
	# initialize players
	initialize_players()
	
	# initialize board state
	initialize_board_state()


func reset_all_states():
	# reset player states
	for i in range(self.num_players):
		update_player_state(
			i, 
			{
				"soldier": self.total_soldiers,
				"leader": 1,
				"active": true,
				"score": 0,
				"territories": [],
				"used_card": false
			}
		)
	print(self.players)
	current_player = 0
	
	# reset board states
	initialize_board_state()
	
	# reset card states
	current_card = null
	
	# reset turn state
	current_phase = TurnPhase.CHOICE


func initialize_players():
	self.players = []  # this is needed as initialize can be called from main menu
	for player in range(self.num_players):
		self.players.append({})
	
	for i in range(self.num_players):
		update_player_state(
			i, 
			{
				"soldier": self.total_soldiers,
				"leader": 1,
				"active": true,
				"score": 0,
				"territories": [],
				"used_card": false
			}
		)


func initialize_board_state():
	"""Randomly assign points and initialize board state."""
	# generate random points
	var points = Array(range(2, 2 + self.num_territories))  # 2 to 12
	points.shuffle()
	
	# self index to points array
	self.board_state["territory_points"] = points
	
	# initialize board state
	self.board_state["territory_tally"] = []
	for territory_index in range(self.num_territories):
		var territory_tally = []
		for i in range(self.num_players):
			territory_tally.append(
				{"soldier": 0, "leader": 0, "reinforcement": 0}
			)
		self.board_state["territory_tally"].append(territory_tally)
	
	# create `all` connection
	for i in range(self.num_territories):
		self.board_state["territory_connections"][i]["all"] = (
			self.board_state["territory_connections"][i]["land"] +
			self.board_state["territory_connections"][i]["water"]
		)


func update_player_state(player_index: int, state_dict: Dictionary):
	self.players[player_index].merge(state_dict, true)


func update_board_tally(territory_index: int, player_index: int, state_dict: Dictionary):
	self.board_state["territory_tally"][territory_index][player_index].merge(state_dict, true)


func update_board_tally_by_delta(territory_index: int, player_index: int, delta_dict: Dictionary):
	# example delta_dict = {"soldier": 1, "leader": 0}, ie adding 1 soldier
	for key in delta_dict.keys():
		self.board_state["territory_tally"][territory_index][player_index][key] += delta_dict[key]


func update_game_state_on_deployed(player_index, territory_index, deploy_count, has_leader):
	"""This function alone should handle changes between deployment states."""
	#region update board tally (board_state["territory_tally"])
	if has_leader:
		if deploy_count >= 0:  # normal game state, add pieces
			update_board_tally_by_delta(
				territory_index, player_index, {"soldier": deploy_count - 1, "leader": 1}
			)
		else:  # when reverting or removing pieces, deploy count is negative
			# eg, when removing 2 pieces (deploy count = -2) with leader, remove 1 from soldier
			update_board_tally_by_delta(
				territory_index, player_index, {"soldier": deploy_count + 1, "leader": -1}
			)
	else:
		update_board_tally_by_delta(
			territory_index, player_index, {"soldier": deploy_count}
		)
	print("current tally --------------------------------------")
	print(board_state["territory_tally"])
	#endregion
	
	#region update territories tagged to the player (players["territories"])
	if deploy_count > 0:  # if normal game play, add territory to the list if not already there
		if not territory_index in self.players[player_index]["territories"]:
			self.players[player_index]["territories"].append(territory_index)
	
	# if removing pieces and there are no pieces left on this territory, remove
	elif deploy_count < 0:
		if (
			self.board_state["territory_tally"][territory_index][player_index]["soldier"] +
			self.board_state["territory_tally"][territory_index][player_index]["leader"]
		) <= 0:
			self.players[player_index]["territories"].erase(territory_index)
	#endregion
	
	#region update player piece count (players["soldier"], players["leader"])
	if deploy_count > 0:
		if has_leader:
			self.players[player_index]["leader"] -= 1
			self.players[player_index]["soldier"] -= deploy_count - 1
		else:
			self.players[player_index]["soldier"] -= deploy_count
	
	# if reverting (deploy_count will be negative)
	elif deploy_count < 0:  # eg, if -2
		if has_leader:  # eg if has leader, then go up 1 leader, 1 solder
			self.players[player_index]["leader"] += 1
			self.players[player_index]["soldier"] += (-deploy_count) - 1
		else:  # eg, go up 2 soldiers
			self.players[player_index]["soldier"] += (-deploy_count)
	print("current player state ---------------------------------")
	print(players)
	#endregion
