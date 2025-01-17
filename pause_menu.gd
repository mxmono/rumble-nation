extends Control

func _ready():
	$PanelContainer/VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$PanelContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_button_pressed)
	$PanelContainer/VBoxContainer/ExitToStartButton.pressed.connect(_on_exit_to_start_button_pressed)
	$PanelContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit_button_pressed)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			get_tree().paused = false
			hide()
		else:
			get_tree().paused = true
			show()


func _on_resume_button_pressed():
	hide()
	get_tree().paused = false


func _on_restart_button_pressed():
	get_tree().paused = false
	GameState.reset_all_states()
	get_tree().reload_current_scene()
	

func _on_exit_to_start_button_pressed():
	get_tree().paused = false
	GameState.reset_all_states()
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_exit_button_pressed():
	get_tree().quit()
