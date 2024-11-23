extends Node

signal deploy_state_updated

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
var current_dice: Array = []
var player_priority: Array = []  # out sequence, values are player ids
var placement: Array = []  # winning placement, first player is the first place

# presets
const PLAYER_PRESETS = [
	{
		"name": "Reddo",
		"icon": preload("res://icons/char1.png"),
		"icon_leader": preload("res://icons/lead1.png"),
		"reinforce":  preload("res://icons/reinforce1.png"),
		"color": Color(0.97, 0.35, 0.48),
		"alt_atlas_id": 1,
	},
	{
		"name": "Blu",
		"icon": preload("res://icons/char2.png"),
		"icon_leader": preload("res://icons/lead2.png"),
		"reinforce":  preload("res://icons/reinforce2.png"),
		"color": Color(0, 0.58, 0.71),
		"alt_atlas_id": 2,
	},
	{
		"name": "Yello",
		"icon": preload("res://icons/char3.png"),
		"icon_leader": preload("res://icons/lead3.png"),
		"reinforce":  preload("res://icons/reinforce3.png"),
		"color": Color(0.79, 0.49, 0.24),
		"alt_atlas_id": 3,
	},
	{
		"name": "Greeny",
		"icon": preload("res://icons/char4.png"),
		"icon_leader": preload("res://icons/lead4.png"),
		"reinforce":  preload("res://icons/reinforce4.png"),
		"color": Color(0, 0.57, 0.53),
		"alt_atlas_id": 4,
	},
]
const CARDS = ["Kasei", "Monomi", "Hitojichi", "Tsuihou", "Muhon", "Otori", "Suigun", "Yamagoe", "Taikyaku", "Shinobi", "Buntai", "Jouraku"]
const LEADERS = ["Mouri", "Chosokabe", "Uesugi", "Oda", "Takeda"]

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
	],
	"territory_winner": [],
}
var drawn_cards = []
var drawn_leaders = []


func _ready() -> void:
	# initialize players
	initialize_players()
	
	# initialize board state
	initialize_board_state()
	
	# deal cards and leaders
	deal_cards()
	deal_leaders()


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
				"used_card": false,
				"used_leader": false,
				"priority": -1,
				"placement": -1,
			}
		)
	print(self.players)
	current_player = 0
	self.player_priority = []
	self.placement = []
	
	# reset dice
	current_dice = []
	
	# reset board states
	initialize_board_state()
	
	# reset card states
	drawn_cards = []
	drawn_leaders = []
	current_card = null
	deal_cards()
	deal_leaders()
	
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
				"used_card": false,
				"used_leader": false,
				"priority": -1,
				"placement": -1,
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
	
	# clear winners
	self.board_state["territory_winner"] = []


func deal_cards():
	"""Deal tactics cards based on number of players."""
	var n_cards = self.num_players + 1
	self.drawn_cards = []
	var cards = CARDS.duplicate()
	cards.shuffle()
	if cards.size() >= n_cards:
		self.drawn_cards = cards.slice(0, n_cards)
	else:
		# Allow replacements: draw numbers with potential duplicates
		for i in range(n_cards):
			var random_index = randi() % cards.size()
			self.drawn_cards.append(cards[random_index])


func deal_leaders():
	"""Deal leader cards."""
	var n_leaders = self.num_players
	self.drawn_leaders = []
	var leaders = LEADERS.duplicate()
	leaders.shuffle()
	if leaders.size() >= n_leaders:
		self.drawn_leaders = leaders.slice(0, n_leaders)
	else:
		# Allow replacements: draw numbers with potential duplicates
		for l in range(n_leaders):
			var random_index = randi() % leaders.size()
			self.drawn_leaders.append(leaders[random_index])


func update_dice(dice_reults: Array):
	self.current_dice = dice_reults


func update_player_state(player_index: int, state_dict: Dictionary):
	self.players[player_index].merge(state_dict, true)
	# as num of players change, need to redeal cards
	deal_cards()
	deal_leaders()


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
	#print("current tally --------------------------------------")
	#print(board_state["territory_tally"])
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
	#print("current player state ---------------------------------")
	#print(players)
	#endregion
	
	# emit signals for ui drawing etc.
	deploy_state_updated.emit()


func all_players_out() -> bool:
	for player in self.players:
		if player["active"]:
			return false 
	return true
