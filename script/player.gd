extends CharacterBody3D

# Движение
var speed = 5.0
var jump_velocity = 7
var gravity = 15.0

# Бой
var base_damage = 10
var current_damage = 10
var attack_cooldown = 0.5
var can_attack = true

var player_health = 50
var max_health = 50

# Оружие
var has_weapon = false
var weapon_damage = 0
var weapon_durability = 0
var weapon_name = ""
var nearby_weapon = null

# Анимации
@onready var animated_sprite = $AnimatedSprite3D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/AttackCollision

func _ready():
	add_to_group("player")
	print("Игрок добавлен в группу player")
	
	# Настройка зоны атаки
	if attack_collision:
		attack_collision.disabled = true
	if attack_area:
		attack_area.monitoring = true
		attack_area.collision_layer = 1
		attack_area.collision_mask = 1
		
		# Устанавливаем начальную позицию зоны атаки (справа)
		attack_area.position.x = 1.0
	
	# Создаём зону подбора оружия
	var pickup_area = Area3D.new()
	pickup_area.name = "PickupArea"
	add_child(pickup_area)
	
	var pickup_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.5, 2.5, 2.5)
	pickup_collision.shape = box_shape
	pickup_area.add_child(pickup_collision)
	
	pickup_area.collision_layer = 1
	pickup_area.collision_mask = 1
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	pickup_area.area_exited.connect(_on_pickup_area_exited)
	pickup_area.monitoring = true
	pickup_area.monitorable = true
	
	print("PickupArea создана!")
	print("AttackArea найден: ", attack_area != null)
	print("AttackCollision найден: ", attack_collision != null)

var is_attacking = false

func _physics_process(delta):
	var direction = 0
	
	if Input.is_action_just_pressed("e"):
		print("nearby_weapon: ", nearby_weapon, " has_weapon: ", has_weapon)
	
	if Input.is_action_pressed("a"):
		direction = -1
	elif Input.is_action_pressed("d"):
		direction = 1
	
	velocity.x = direction * speed
	
	# ===== УПРАВЛЕНИЕ АНИМАЦИЯМИ =====
	if not is_attacking:
		if not is_on_floor():
			if animated_sprite.sprite_frames.has_animation("jump"):
				animated_sprite.play("jump")
		elif direction != 0:
			if animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.play("walk")
		else:
			if animated_sprite.sprite_frames.has_animation("idle"):
				animated_sprite.play("idle")
	
	# ===== ПОВОРОТ СПРАЙТА (flip_h) =====
	if direction != 0:
		animated_sprite.flip_h = direction < 0
		
		# Поворачиваем зону атаки
		if attack_area:
			attack_area.position.x = -1.0 if direction < 0 else 1.0
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Атака
	if Input.is_action_just_pressed("m1") and can_attack and not is_attacking:
		perform_attack()
	
	# Подбор оружия
	if Input.is_action_just_pressed("e") and nearby_weapon and not has_weapon:
		pickup_weapon(nearby_weapon)
		nearby_weapon.queue_free()
		nearby_weapon = null
	
	move_and_slide()

func perform_attack():
	print("=== АТАКА ===")
	can_attack = false
	is_attacking = true
	
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	if attack_collision:
		attack_collision.disabled = false
	
	await get_tree().create_timer(0.25).timeout
	
	var bodies = []
	if attack_area:
		bodies = attack_area.get_overlapping_bodies()
	
	for body in bodies:
		if body.has_method("take_damage"):
			print("Наношу урон ", current_damage)
			body.take_damage(current_damage)
			
			if has_weapon:
				weapon_durability -= 1
				if weapon_durability <= 0:
					break_weapon()
	
	await get_tree().create_timer(0.25).timeout
	
	if attack_collision:
		attack_collision.disabled = true
	
	is_attacking = false
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func pickup_weapon(weapon):
	if has_weapon:
		return
	
	has_weapon = true
	weapon_damage = weapon.damage
	weapon_durability = weapon.max_durability
	weapon_name = weapon.weapon_name
	current_damage = weapon_damage
	
	print("Подобрано оружие: ", weapon_name)

func break_weapon():
	has_weapon = false
	current_damage = base_damage
	print("Оружие сломалось!")

func _on_pickup_area_entered(area):
	var weapon = area.get_parent()
	if weapon.is_in_group("weapons"):
		nearby_weapon = weapon
		print("Рядом оружие! Нажмите E")
	elif area.is_in_group("weapons"):
		nearby_weapon = area
		print("Рядом оружие! Нажмите E")

func _on_pickup_area_exited(area):
	var weapon = area.get_parent()
	if weapon.is_in_group("weapons") and nearby_weapon == weapon:
		nearby_weapon = null
	elif area.is_in_group("weapons") and nearby_weapon == area:
		nearby_weapon = null

func take_damage(amount):
	player_health -= amount
	print("Игрок получил урон ", amount, ", осталось здоровья: ", player_health)
	
	if animated_sprite:
		animated_sprite.modulate = Color(1, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if player_health <= 0:
		die()

func die():
	print("ИГРОК УМЕР!")
	set_process(false)
	set_physics_process(false)
	
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
