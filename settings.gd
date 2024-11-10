extends Node

var num_players: int = 2
var player_piece_icons = [
	preload("res://icons/p1.png"),
	preload("res://icons/p2.png"),
	preload("res://icons/p3.png"),
	preload("res://icons/p4.png"),
]
var players = [
	{
		"name": "Player 1",
		"icon": player_piece_icons[0],
		"color": Color("red"),
	},
	{
		"name": "Player 2",
		"icon": player_piece_icons[1],
		"color": Color("blue"),
	},
	{
		"name": "Player 3",
		"icon": player_piece_icons[2],
		"color": Color("yellow"),
	},
	{
		"name": "Player 4",
		"icon": player_piece_icons[3],
		"color": Color("green"),
	}
]
