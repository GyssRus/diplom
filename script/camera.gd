extends Camera3D

# Настройки следования
var target: Node3D = null           # Цель (игрок)
var follow_speed = 5.0              # Скорость следования (плавность)
var offset = Vector3(0, 1.5, 5)     # Относительное положение камеры

func _ready():
	# Ищем игрока на сцене
	target = get_tree().get_first_node_in_group("player")
	if target == null:
		print("Ошибка: Камера не нашла игрока!")

func _physics_process(delta):
	if target == null:
		target = get_tree().get_first_node_in_group("player")
		return
	
	# Целевая позиция (позиция игрока + смещение)
	var target_position = target.global_position + offset
	
	# Плавное движение камеры
	global_position = global_position.lerp(target_position, follow_speed * delta)
