extends Node

var num_players: int = 2
var total_soldiers: int = 16

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

var players = []
