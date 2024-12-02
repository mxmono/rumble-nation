extends Node2D

@onready var game_scene = $".."
@onready var control_scene = $"../Control"


func _ready() -> void:
	$PiecesLeftLabel.bbcode_enabled = true
	update_peices_left_label()
	GameState.deploy_state_updated.connect(_on_deploy_state_updated)
	game_scene.phase_started.connect(_on_phase_started)
	control_scene.dice_rolled.connect(_on_dice_rolled)
	control_scene.dice_selected.connect(_on_dice_selected)
	control_scene.card_move_confirmed.connect(_on_card_move_confirmed)
	$LogButton.pressed.connect(_on_log_button_pressed)


func _on_deploy_state_updated():
	update_peices_left_label()


func _on_phase_started(phase):
	update_peices_left_label()
	
	# update log
	var current_player_name = GameState.players[GameState.current_player]["name"]
	
	match GameState.current_phase:

		GameState.TurnPhase.CHOICE:
			add_to_log("[u]%s's turn[/u]" % current_player_name)


func add_to_log(text: String):
	$LogBG/LogLabel.append_text("\n" + text)


func update_peices_left_label():
	$PiecesLeftLabel.text = ""
	var i = 0
	for player in GameState.players:
		
		# if used either card or both
		var used_card_icon: String = ""
		if player.get("used_card"):
			if player.get("used_leader"):
				used_card_icon = "[img]res://icons/card-both.png[/img]"
			else:
				used_card_icon = "[img]res://icons/card.png[/img]"
		else:
			if player.get("used_leader"):
				used_card_icon = "[img]res://icons/card-leader.png[/img]"
		
		# if player is out and the sequnce
		var player_out_icon: String = ""
		if player["priority"] != -1:
			player_out_icon = "[img]res://icons/sword%s.png[/img]" % (player["priority"] + 1)
		
		if i == 0:
			$PiecesLeftLabel.append_text("[center]")
		
		$PiecesLeftLabel.append_text(
			"%s[color=%s]%s: [img width=32]%s[/img]x%s [img]%s[/img]x%s %s%s[/color]%s   "
			%
			[
				"[u][b]" if i == GameState.current_player else "",
				player["color"].to_html(),
				player["name"],
				player["icon_leader"].resource_path,
				player["leader"],
				player["icon"].resource_path,
				player["soldier"],
				used_card_icon,
				player_out_icon,
				"[/b][/u]" if i == GameState.current_player else "",
			]
		)
		
		i += 1


func _on_dice_rolled(dice_results: Array, move_options: Array):
	add_to_log(
		"└ %s rolled %s" % [
			GameState.players[GameState.current_player]["name"], GameState.current_dice
		]
	)


func _on_dice_selected(territory_index: int, deploy_count: int, is_leader: bool):
	add_to_log(
		"└ %s placed %s%s on Territory %s" % [
			GameState.players[GameState.current_player]["name"], 
			deploy_count,
			" (L)" if is_leader else "",
			GameState.board_state["territory_points"][territory_index],
		]
	)


func _on_card_move_confirmed():
		add_to_log(
		"└ %s used a card: %s" % [
			GameState.players[GameState.current_player]["name"], 
			GameState.current_card["card_name"],
		]
	)


func _on_log_button_pressed():
	if $LogBG.visible:
		$LogBG.hide()
	else:
		$LogBG.show()
