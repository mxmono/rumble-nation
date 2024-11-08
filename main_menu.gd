extends Control

@onready var start_game_button = $PanelContainer/VBoxContainer/StartGameButton

const GAME_OPTIONS_PARENT = "GameOptions/MarginContainer/VBoxContainer/GameSettings/"
const PLAYER_SETTINGS = "GameOptions/MarginContainer/VBoxContainer/PlayerSettings/"
@onready var num_players_option = get_node(GAME_OPTIONS_PARENT + "NumPlayersOption")
@onready var player_settings = []

func _ready() -> void:
	
	# get player settings fields
	for i in range(4):
		player_settings.append(
			{
				"name": get_node(PLAYER_SETTINGS + "Player%s/LineEdit" % str(i)),
				"color": get_node(PLAYER_SETTINGS + "Player%s/ColorPickerButton" % str(i)),
			}
		)
		player_settings[i]["name"].text_changed.connect(_on_player_name_changed.bind(i))
		player_settings[i]["color"].color_changed.connect(_on_player_color_changed.bind(i))
	
	# connect buttons and updates
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	num_players_option.item_selected.connect(_on_num_players_option_selected)
	
	
func _on_start_game_button_pressed():
	# update global num_players in autload settings
	Settings.players = Settings.players.slice(0, Settings.num_players)
	get_tree().change_scene_to_file("res://game_controller.tscn")

func _on_num_players_option_selected(selected_option):
	# UI: update player settings section (if only 2 players, only show configuration for 2)
	if Settings.num_players == 2:
		get_node(PLAYER_SETTINGS + "Player2").hide()
		get_node(PLAYER_SETTINGS + "Player3").hide()
	
	elif Settings.num_players == 3:
		get_node(PLAYER_SETTINGS + "Player2").show()
		get_node(PLAYER_SETTINGS + "Player3").hide()
		
	elif Settings.num_players == 4:
		get_node(PLAYER_SETTINGS + "Player2").show()
		get_node(PLAYER_SETTINGS + "Player3").show()

func _on_player_name_changed(name, i):
	Settings.players[i]["name"] = name

func _on_player_color_changed(color, i):
	Settings.players[i]["color"] = color
