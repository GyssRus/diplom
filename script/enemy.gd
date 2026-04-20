extends CharacterBody3D

var health = 30
var speed = 2.0
var gravity = 15.0
var attack_damage = 10  # ДОБАВЛЕНО: урон атаки
var can_attack = true   # ДОБАВЛЕНО: можно ли атаковать
var is_attacking = false # ДОБАВЛЕНО: идёт ли атака сейчас

@onready var mesh = $MeshInstance3D
@onready var detection_area = $DetectionArea
@onready var detection_collision = $DetectionArea/DetectionCollision
@onready var attack_area = $MeshInstance3D/AttackArea
@onready var attack_collision = $MeshInstance3D/AttackArea/AttackCollision

var player = null
var player_in_range = false  # Игрок в зоне атаки
var player_detected = false  # Игрок в зоне обнаружения

func _ready():
	# Подключаем сигналы для зоны обнаружения
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	
	# Подключаем сигналы для зоны атаки
	attack_area.body_entered.connect(_on_player_entered)
	attack_area.body_exited.connect(_on_player_exited)
	
	# Включаем обе зоны
	detection_collision.disabled = false
	attack_collision.disabled = false
	detection_area.monitoring = true
	attack_area.monitoring = true
	
	add_to_group("enemies")
	print("Враг создан! Здоровье: ", health)

func _physics_process(delta):
	# Ищем игрока, если ещё не нашли
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# ДВИЖЕНИЕ ТОЛЬКО ЕСЛИ ИГРОК ОБНАРУЖЕН И НЕ АТАКУЕТ
	if player_detected and player and is_instance_valid(player) and not is_attacking:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * speed
		
		# Поворот в сторону движения
		if direction != 0:
			mesh.scale.x = -1 if direction < 0 else 1
	else:
		velocity.x = 0  # Стоим на месте
	
	# ДОБАВЛЕНО: если игрок в зоне атаки и можно атаковать — начинаем атаку
	if player_in_range and can_attack and not is_attacking:
		start_attack()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

# ДОБАВЛЕНО: функция атаки
func start_attack():
	print("[Атака] Начинаю атаку!")
	is_attacking = true
	can_attack = false
	
	# Останавливаем движение
	velocity.x = 0
	
	# Задержка перед ударом (замах) — 0.3 секунды
	await get_tree().create_timer(0.3).timeout
	
	# Проверяем, что игрок всё ещё в зоне атаки
	if player_in_range and player and is_instance_valid(player):
		print("[Атака] Удар! Наношу урон ", attack_damage)
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	else:
		print("[Атака] Промах! Игрок вышел из зоны")
	
	# Перезарядка (1 секунда)
	await get_tree().create_timer(1.0).timeout
	can_attack = true
	is_attacking = false
	print("[Атака] Готов к новой атаке")

# Зона обнаружения (большая сфера)
func _on_player_detected(body):
	if body.is_in_group("player"):
		player_detected = true
		print("[Обнаружение] Игрок ЗАМЕЧЕН! Начинаю движение")

func _on_player_lost(body):
	if body.is_in_group("player"):
		player_detected = false
		print("[Обнаружение] Игрок ПОТЕРЯН! Останавливаюсь")

# Зона атаки (маленький бокс перед врагом)
func _on_player_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		print("[Атака] Игрок в зоне удара!")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("[Атака] Игрок вышел из зоны удара")

func take_damage(amount):
	health -= amount
	print("Враг получил урон ", amount, ", осталось ", health)
	
	if mesh:
		var material = mesh.get_active_material(0)
		if material:
			material.albedo_color = Color(1, 0, 0)
			if is_instance_valid(get_tree()):
				await get_tree().create_timer(0.1).timeout
			material.albedo_color = Color(1, 0.5, 0.5)
	
	if health <= 0:
		print("Враг умер!")
		queue_free()
