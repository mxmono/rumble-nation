extends Node2D

@onready var game_scene = $".."


func _ready() -> void:
	$PiecesLeftLabel.bbcode_enabled = true
	update_peices_left_label()
	GameState.deploy_state_updated.connect(_on_deploy_state_updated)
	game_scene.phase_started.connect(_on_phase_started)
	

func _on_deploy_state_updated():
	update_peices_left_label()


func _on_phase_started(phase):
	update_peices_left_label()


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
