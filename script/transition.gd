extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	# Начинаем с прозрачного
	color_rect.modulate.a = 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS

# Затемнение (закрыть сцену)
func fade_out(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished
	SignalBus.transition_faded_out.emit()  # Можно использовать сигнал

# Проявление (открыть новую сцену)
func fade_in(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished

# Полный переход на другую сцену
func change_scene(scene_path: String, fade_duration: float = 0.5):
	await fade_out(fade_duration)
	get_tree().change_scene_to_file(scene_path)
	fade_in(fade_duration)
