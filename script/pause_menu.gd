extends CanvasLayer

func _ready():
	# По умолчанию скрыто
	visible = false
	
	# Подключаем кнопки	
	$CenterContainer/Panel/VBoxContainer/resume.pressed.connect(_on_resume_pressed)
	$CenterContainer/Panel/VBoxContainer/quit.pressed.connect(_on_quit_pressed)

	

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
