extends CharacterBody3D

# ============================================
# 1. НАСТРОЙКИ (меняйте параметры здесь)
# ============================================

# Характеристики врага
var health = 15
var speed = 4.0
var gravity = 15.0
var attack_damage = 0.5

# Атака
var can_attack = true
var is_attacking = false
var attack_speed_multiplier = 0.5  # Замедление во время атаки (0.5 = 50% скорости)

# Зоны
var attack_distance = 1.0  # Расстояние зоны атаки от центра

# ============================================
# 2. ССЫЛКИ НА УЗЛЫ
# ============================================

@onready var animated_sprite = $AnimatedSprite3D
@onready var detection_area = $DetectionArea
@onready var detection_collision = $DetectionArea/DetectionCollision
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/AttackCollision

# ============================================
# 3. СОСТОЯНИЯ
# ============================================

var player = null
var player_in_range = false      # Игрок в зоне атаки
var player_detected = false      # Игрок в зоне обнаружения

# ============================================
# 4. ИНИЦИАЛИЗАЦИЯ
# ============================================

func _ready():
	setup_signals()
	setup_collisions()
	setup_sprite()
	
	add_to_group("enemies")
	print("Быстрый враг создан! Здоровье: ", health)

func setup_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	attack_area.body_entered.connect(_on_player_entered_attack_range)
	attack_area.body_exited.connect(_on_player_exited_attack_range)

func setup_collisions():
	detection_collision.disabled = false
	attack_collision.disabled = false
	detection_area.monitoring = true
	attack_area.monitoring = true
	attack_area.position.x = attack_distance

func setup_sprite():
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED

# ============================================
# 5. ДВИЖЕНИЕ
# ============================================

func _physics_process(delta):
	find_player()
	
	if player_detected and is_player_valid():
		var direction = get_direction_to_player()
		apply_movement(direction)
		update_animations(direction)
		update_sprite_direction(direction)
		update_attack_area_position(direction)
	else:
		stop_movement()
		play_idle_animation()
	
	try_to_attack()
	apply_gravity(delta)
	
	move_and_slide()

func find_player():
	if player == null:
		player = get_tree().get_first_node_in_group("player")

func is_player_valid() -> bool:
	return player and is_instance_valid(player)

func get_direction_to_player() -> int:
	return sign(player.global_position.x - global_position.x)

func apply_movement(direction: int):
	if is_attacking:
		velocity.x = direction * speed * attack_speed_multiplier
	else:
		velocity.x = direction * speed

func stop_movement():
	velocity.x = 0

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

# ============================================
# 6. АНИМАЦИИ
# ============================================

func update_animations(direction: int):
	if is_attacking:
		return  # Не меняем анимацию во время атаки
	
	if direction != 0:
		play_walk_animation()
	else:
		play_idle_animation()

func play_walk_animation():
	if animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")

func play_idle_animation():
	if not is_attacking and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func update_sprite_direction(direction: int):
	if direction != 0:
		animated_sprite.flip_h = direction < 0

func update_attack_area_position(direction: int):
	if direction != 0:
		attack_area.position.x = -attack_distance if direction < 0 else attack_distance

# ============================================
# 7. ОБНАРУЖЕНИЕ ИГРОКА
# ============================================

func _on_player_detected(body):
	if body.is_in_group("player"):
		player_detected = true
		print("[Обнаружение] Быстрый враг: игрок ЗАМЕЧЕН!")

func _on_player_lost(body):
	if body.is_in_group("player"):
		player_detected = false
		print("[Обнаружение] Быстрый враг: игрок ПОТЕРЯН!")

func _on_player_entered_attack_range(body):
	if body.is_in_group("player"):
		player_in_range = true
		print("[Атака] Быстрый враг: игрок в зоне удара!")

func _on_player_exited_attack_range(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("[Атака] Быстрый враг: игрок вышел из зоны удара")

# ============================================
# 8. АТАКА
# ============================================

func try_to_attack():
	if player_in_range and can_attack and not is_attacking:
		start_attack()

func start_attack():
	print("[Атака] Быстрый враг: начинаю атаку!")
	is_attacking = true
	can_attack = false
	
	play_attack_animation()
	await wait_for_attack_windup()
	
	if is_player_still_in_range():
		deal_damage_to_player()
	else:
		print("[Атака] Быстрый враг: промах! Игрок вышел из зоны")
	
	await wait_for_attack_recovery()
	await wait_for_attack_cooldown()
	
	can_attack = true
	is_attacking = false
	print("[Атака] Быстрый враг: готов к новой атаке")

func play_attack_animation():
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

func wait_for_attack_windup():
	await get_tree().create_timer(0.3).timeout

func is_player_still_in_range() -> bool:
	return player_in_range and player and is_instance_valid(player)

func deal_damage_to_player():
	print("[Атака] Быстрый враг: удар! Наношу урон ", attack_damage)
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

func wait_for_attack_recovery():
	await get_tree().create_timer(0.3).timeout

func wait_for_attack_cooldown():
	await get_tree().create_timer(1.0).timeout

# ============================================
# 9. ПОЛУЧЕНИЕ УРОНА И СМЕРТЬ
# ============================================

func take_damage(amount: int):
	health -= amount
	print("Быстрый враг: получил урон ", amount, ", осталось ", health)
	
	play_damage_flash()
	
	if health <= 0:
		die()

func play_damage_flash():
	if animated_sprite:
		animated_sprite.modulate = Color(1, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)

func die():
	print("Быстрый враг: умер!")
	queue_free()
