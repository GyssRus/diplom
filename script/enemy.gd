extends CharacterBody3D

var health = 30
var speed = 2.0
var gravity = 15.0
var attack_damage = 10
var can_attack = true
var is_attacking = false
var attack_speed_multiplier = 0.3

# Узлы (обновлённые)
@onready var animated_sprite = $AnimatedSprite3D
@onready var detection_area = $DetectionArea
@onready var detection_collision = $DetectionArea/DetectionCollision
@onready var attack_area = $AttackArea  # Теперь отдельно, не внутри MeshInstance3D
@onready var attack_collision = $AttackArea/AttackCollision

var player = null
var player_in_range = false
var player_detected = false

func _ready():
	# Подключаем сигналы
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	attack_area.body_entered.connect(_on_player_entered)
	attack_area.body_exited.connect(_on_player_exited)
	
	# Настройка коллизий
	detection_collision.disabled = false
	attack_collision.disabled = false
	detection_area.monitoring = true
	attack_area.monitoring = true
	
	# Устанавливаем начальную позицию зоны атаки (справа)
	attack_area.position.x = 1.0
	
	# Настройка Billboard для спрайта (чтобы всегда смотрел на камеру)
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	add_to_group("enemies")
	print("Враг создан! Здоровье: ", health)

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player_detected and player and is_instance_valid(player):
		var direction = sign(player.global_position.x - global_position.x)
		
		# Движение с учётом атаки
		if is_attacking:
			velocity.x = direction * speed * attack_speed_multiplier
		else:
			velocity.x = direction * speed
		
		# ===== УПРАВЛЕНИЕ АНИМАЦИЯМИ =====
		if not is_attacking:
			if direction != 0:
				if animated_sprite.sprite_frames.has_animation("walk"):
					animated_sprite.play("walk")
			else:
				if animated_sprite.sprite_frames.has_animation("idle"):
					animated_sprite.play("idle")
		
		# ===== ПОВОРОТ СПРАЙТА (flip_h) =====
		if direction != 0:
			animated_sprite.flip_h = direction < 0
			
			# Поворачиваем зону атаки
			attack_area.position.x = -1.0 if direction < 0 else 1.0
	else:
		velocity.x = 0
		# Если не двигаемся и не атакуем — анимация покоя
		if not is_attacking and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	
	# Проверка атаки
	if player_in_range and can_attack and not is_attacking:
		start_attack()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func start_attack():
	print("[Атака] Начинаю атаку!")
	is_attacking = true
	can_attack = false
	
	# Проигрываем анимацию атаки
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	# Задержка перед ударом (замах) — 0.3 секунды
	await get_tree().create_timer(0.3).timeout
	
	# Проверяем, что игрок всё ещё в зоне атаки
	if player_in_range and player and is_instance_valid(player):
		print("[Атака] Удар! Наношу урон ", attack_damage)
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	else:
		print("[Атака] Промах! Игрок вышел из зоны")
	
	# Ждём окончания анимации атаки
	await get_tree().create_timer(0.3).timeout
	
	# Перезарядка
	await get_tree().create_timer(1.0).timeout
	can_attack = true
	is_attacking = false
	print("[Атака] Готов к новой атаке")

func _on_player_detected(body):
	if body.is_in_group("player"):
		player_detected = true
		print("[Обнаружение] Игрок ЗАМЕЧЕН! Начинаю движение")

func _on_player_lost(body):
	if body.is_in_group("player"):
		player_detected = false
		print("[Обнаружение] Игрок ПОТЕРЯН! Останавливаюсь")

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
	
	# Визуальный эффект (мигание белым/красным) для спрайта
	if animated_sprite:
		animated_sprite.modulate = Color(1, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		print("Враг умер!")
		queue_free()
