extends Node2D

@onready var game_scene = get_node("/root/Game")


func _ready() -> void:
	$Main/CloseButton.pressed.connect(_on_close_button_pressed)
	$ShowButton.pressed.connect(_on_show_button_pressed)
	game_scene.game_scored.connect(_on_game_scored)
	
	$Main/HBoxContainer/RematchButton.pressed.connect(_on_rematch_button_pressed)
	$Main/HBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	$Main/HBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)


func update_first_place():
	"""Update icon and text label for first place."""
	var player = GameState.players[GameState.placement[0]]
	
	var player_priority_icon = "res://icons/sword%s.png" % (player["priority"] + 1) 
	
	var used_card_icon: String = ""
	if player.get("used_card"):
		if player.get("used_leader"):
			used_card_icon = "[img width=32]res://icons/card-both.png[/img]"
		else:
			used_card_icon = "[img width=32]res://icons/card.png[/img]"
	else:
		if player.get("used_leader"):
			used_card_icon = "[img width=32]res://icons/card-leader.png[/img]"
	
	$Main/Place1Label.text = ""
	$Main/Place1Label.append_text(
		"[center][font size=48]%s %s [/font][img width=32]%s[/img] %s" %
		[
			player["name"],
			player["score"],
			player_priority_icon,
			used_card_icon,
		]
	)
	
	$Main/AnimatedSprite2D.play(str(player["alt_atlas_id"]))


func update_other_players():
	"""Update icon and text label for 2nd-4th place. Based on how many players there are."""
	var i = 2
	for player_index in GameState.placement.slice(1, GameState.players.size()):
		var player = GameState.players[player_index]
		
		var player_priority_icon = "res://icons/sword%s.png" % (player["priority"] + 1) 
	
		var used_card_icon: String = ""
		if player.get("used_card"):
			if player.get("used_leader"):
				used_card_icon = "res://icons/card-both.png"
			else:
				used_card_icon = "res://icons/card.png"
		else:
			if player.get("used_leader"):
				used_card_icon = "res://icons/card-leader.png"
		
		get_node("Main/Scores/Place%sLabel" % str(i)).text = ""
		get_node("Main/Scores/Place%sLabel" % str(i)).append_text(
			"[img width=32]res://icons/medal%s.png[/img][img width=32]%s[/img][font size=24] %s %s [/font][img width=24]%s[/img] [img width=24]%s[/img]" %
			[
				i,
				player["icon"].resource_path,
				player["name"],
				player["score"],
				player_priority_icon,
				used_card_icon,
			]
		)
		get_node("Main/Scores/Place%sLabel" % str(i)).visible = true
		i += 1


func _on_close_button_pressed():
	$Main.hide()
	$ShowButton.show()


func _on_show_button_pressed():
	$Main.show()
	$ShowButton.hide()


func _on_game_scored():
	
	update_first_place()
	update_other_players()
	
	show()


func _on_main_menu_button_pressed():
	GameState.reset_all_states()
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
	

func _on_rematch_button_pressed():
	# restart the match, with the winning player going first
	var winner = GameState.placement[0]
	GameState.players = [
		GameState.players[winner % GameState.num_players],
		GameState.players[(winner + 1) % GameState.num_players],
		GameState.players[(winner + 2) % GameState.num_players],
		GameState.players[(winner + 3) % GameState.num_players],
	]
	GameState.players = GameState.players.slice(0, GameState.num_players)
	GameState.reset_all_states()
	get_tree().reload_current_scene()
