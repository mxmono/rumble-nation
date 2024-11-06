extends Node

var num_players: int = 2
var player_piece_icons = [
	preload("res://icons/cat.webp"),
	preload("res://icons/bird.webp"),
]
var players = [
	{
		"name": "Player 1",
		"color": "red",
	},
	{
		"name": "Player 2",
		"color": "blue",
	},
	{
		"name": "Player 3",
		"color": "yellow",
	},
	{
		"name": "Player 4",
		"color": "green",
	}
]
