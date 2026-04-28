extends CharacterBody3D

# Характеристики
var health = 15
var speed = 4.0
var gravity = 15.0
var attack_damage = 8
var can_attack = true
var is_attacking = false
var attack_speed_multiplier = 0.5

# Узлы
@onready var animated_sprite = $AnimatedSprite3D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
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
	detection_area.monitoring = true
	attack_area.monitoring = true
	attack_collision.disabled = false
	
	# Настройка Billboard для спрайта
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	add_to_group("enemies")
	print("Быстрый враг создан! Здоровье: ", health)

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player_detected and player and is_instance_valid(player):
		var direction = sign(player.global_position.x - global_position.x)
		
		# Движение
		if is_attacking:
			velocity.x = direction * speed * attack_speed_multiplier
		else:
			velocity.x = direction * speed
		
		# Анимации
		if not is_attacking:
			if direction != 0:
				if animated_sprite.sprite_frames.has_animation("walk"):
					animated_sprite.play("walk")
			else:
				if animated_sprite.sprite_frames.has_animation("idle"):
					animated_sprite.play("idle")
		
		# Поворот спрайта и зоны атаки
		if direction != 0:
			animated_sprite.flip_h = direction < 0
			attack_area.position.x = -1.0 if direction < 0 else 1.0
	else:
		velocity.x = 0
		if not is_attacking and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
	
	# Проверка атаки
	if player_in_range and can_attack and not is_attacking:
		start_attack()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func start_attack():
	print("[FastEnemy] Начинаю атаку!")
	is_attacking = true
	can_attack = false
	
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	
	if player_in_range and player and is_instance_valid(player):
		print("[FastEnemy] Удар! Наношу урон ", attack_damage)
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	else:
		print("[FastEnemy] Промах!")
	
	await get_tree().create_timer(0.3).timeout
	
	await get_tree().create_timer(1.0).timeout
	can_attack = true
	is_attacking = false
	print("[FastEnemy] Готов к новой атаке")

func _on_player_detected(body):
	if body.is_in_group("player"):
		player_detected = true
		print("[FastEnemy] Игрок замечен!")

func _on_player_lost(body):
	if body.is_in_group("player"):
		player_detected = false
		print("[FastEnemy] Игрок потерян!")

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		print("[FastEnemy] Игрок в зоне удара!")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("[FastEnemy] Игрок вышел из зоны удара")

func take_damage(amount):
	health -= amount
	print("[FastEnemy] Получил урон ", amount, ", осталось ", health)
	
	if animated_sprite:
		animated_sprite.modulate = Color(1, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		print("[FastEnemy] Умер!")
		queue_free()
