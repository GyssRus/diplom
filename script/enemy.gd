extends CharacterBody3D

var speed = 2.0
var gravity = 15.0
var player = null

func _ready():
	add_to_group("enemies")
	print("Враг создан!")

func _physics_process(delta):
	# Ищем игрока
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# Двигаемся к игроку
	if player:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * speed
		#print("Двигаюсь к игроку, направление: ", direction)  # Отладка
	else:
		velocity.x = 0
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func take_damage(amount):
	print("Враг получил урон!")
