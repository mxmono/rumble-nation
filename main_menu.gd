extends Control

@onready var start_game_button = $PanelContainer/VBoxContainer/StartGameButton

const GAME_OPTIONS_PARENT = "GameOptions/Local/VBoxContainer/GameSettings/"
const PLAYER_SETTINGS = "GameOptions/Local/VBoxContainer/PlayerSettings/"
const CONNECT_PANEL = "GameOptions/Remote/HBoxContainer/Connect/"
const LOBBY_PANEL = "GameOptions/Remote/HBoxContainer/Lobby/"
@onready var num_players_option = get_node(GAME_OPTIONS_PARENT + "NumPlayersOption")
@onready var player_settings = []

func _ready() -> void:
	
	# local
	# get player settings fields
	for i in range(4):
		player_settings.append(
			{
				"name": get_node(PLAYER_SETTINGS + "Player%s/LineEdit" % str(i)),
				"icon": get_node(PLAYER_SETTINGS + "Player%s/Icon/OptionButton" % str(i)),
				"color": get_node(PLAYER_SETTINGS + "Player%s/Icon/ColorPickerButton" % str(i)),
			}
		)
		player_settings[i]["name"].text_changed.connect(_on_player_name_changed.bind(i))
		player_settings[i]["icon"].item_selected.connect(_on_player_icon_changed.bind(i))
		#player_settings[i]["color"].color_changed.connect(_on_player_color_changed.bind(i))
	
	# get default selection
	update_player_settings()
	
	# connect buttons and updates
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	num_players_option.item_selected.connect(_on_num_players_option_selected)
	
	# remote
	Gamestate.connection_failed.connect(_on_connection_failed)
	Gamestate.connection_succeeded.connect(_on_connection_success)
	Gamestate.player_list_changed.connect(refresh_lobby)
	#Gamestate.game_ended.connect(_on_game_ended)
	#Gamestate.game_error.connect(_on_game_error)

	get_node(CONNECT_PANEL + "HostButton").pressed.connect(_on_host_pressed)
	get_node(CONNECT_PANEL + "JoinButton").pressed.connect(_on_join_pressed)

func update_player_settings():
	"""Update Settings on player selection."""
	Settings.num_players = num_players_option.selected + 2  # option 0 is 2 players
	Settings.players = []
	for i in range(Settings.num_players):
		var preset_index = player_settings[i]["icon"].selected
		Settings.players.append(
			{
				"name": player_settings[i]["name"].text,
				"icon": Settings.player_presets[preset_index]["icon"],
				"icon_leader": Settings.player_presets[preset_index]["leader"],
				"icon_reinforce": Settings.player_presets[preset_index]["reinforce"],
				"color": Settings.player_presets[preset_index]["color"]
			}
		)

func _on_start_game_button_pressed():
	Gamestate.begin_game()

func _on_num_players_option_selected(selected_option):
	# UI: update player settings section (if only 2 players, only show configuration for 2)
	if selected_option + 2 == 2:
		get_node(PLAYER_SETTINGS + "Player2").hide()
		get_node(PLAYER_SETTINGS + "Player3").hide()
	
	elif  selected_option + 2 == 3:
		get_node(PLAYER_SETTINGS + "Player2").show()
		get_node(PLAYER_SETTINGS + "Player3").hide()
		
	elif  selected_option + 2 == 4:
		get_node(PLAYER_SETTINGS + "Player2").show()
		get_node(PLAYER_SETTINGS + "Player3").show()
	
	update_player_settings()

func _on_player_name_changed(name, i):
	update_player_settings()

func _on_player_icon_changed(icon, i):

	update_player_settings()
	
	# if the name is in default names or is empty, also change the name with the icon selection
	var preset_names = []
	for preset in Settings.player_presets:
		preset_names.append(preset["name"])
	
	if preset_names.has(Settings.players[i]["name"]) or Settings.players[i]["name"] == "":
		var preset_index = player_settings[i]["icon"].selected
		player_settings[i]["name"].set_text(Settings.player_presets[preset_index]["name"])
	
	update_player_settings()

#func _on_player_color_changed(color, i):
	#update_player_settings()

#region remote
func _on_host_pressed():
	if get_node(CONNECT_PANEL + "NameEdit").text == "":
		$GameOptions/Remote/ErrorLabel.text = "Invalid name!"
		return

	$GameOptions/Remote/ErrorLabel.text = ""

	var player_name = get_node(CONNECT_PANEL + "NameEdit").text
	Gamestate.host_game(player_name)
	refresh_lobby()

func _on_join_pressed():
	if  get_node(CONNECT_PANEL + "NameEdit").text == "":
		$GameOptions/Remote/ErrorLabel.text = "Invalid name!"
		return

	var ip = get_node(CONNECT_PANEL + "IPEdit").text
	if not ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid IP address!"
		return

	$GameOptions/Remote/ErrorLabel.text = ""
	get_node(CONNECT_PANEL + "HostButton").disabled = true
	get_node(CONNECT_PANEL + "JoinButton").disabled = true

	var player_name = get_node(CONNECT_PANEL + "NameEdit").text
	Gamestate.join_game(ip, player_name)

func _on_connection_success():
	#$Connect.hide()
	#$Players.show()
	pass

func _on_connection_failed():
	#$Connect/Host.disabled = false
	#$Connect/Join.disabled = false
	$GameOptions/Remote/ErrorLabel.set_text("Connection failed.")

#func _on_game_ended():
	#show()
	#$Connect.show()
	#$Players.hide()
	#$Connect/Host.disabled = false
	#$Connect/Join.disabled = false
#
#func _on_game_error(errtxt):
	#$ErrorDialog.dialog_text = errtxt
	#$ErrorDialog.popup_centered()
	#$Connect/Host.disabled = false
	#$Connect/Join.disabled = false

func refresh_lobby():
	var players = Gamestate.get_player_list()
	players.sort()
	get_node(LOBBY_PANEL + "PlayerList").clear()
	get_node(LOBBY_PANEL + "PlayerList").add_item(Gamestate.get_player_name() + " (You)")
	for p in players:
		get_node(LOBBY_PANEL + "PlayerList").add_item(p)

	$PanelContainer/VBoxContainer/StartGameButton.disabled = not multiplayer.is_server()

func _on_start_pressed():
	Gamestate.begin_game()
#endregion
