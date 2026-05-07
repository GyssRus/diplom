extends CharacterBody3D

# ============================================
# 1. НАСТРОЙКИ
# ============================================

# Движение
var speed = 5.0
var jump_velocity = 7
var gravity = 15.0

# Бой
var base_damage = 10
var current_damage = 10
var attack_cooldown = 0.5
var can_attack = true
var is_attacking = false

# Здоровье
var player_health = 4.0
var max_health = 4.0

# Оружие
var has_weapon = false
var weapon_damage = 0
var weapon_durability = 0
var weapon_name = ""
var nearby_weapon = null

# ============================================
# 2. ССЫЛКИ НА УЗЛЫ
# ============================================

@onready var pause_menu = get_tree().current_scene.get_node("PauseMenu")
@onready var ui = $UI
@onready var animated_sprite = $AnimatedSprite3D
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/AttackCollision

# ============================================
# 3. ИНИЦИАЛИЗАЦИЯ
# ============================================

func _ready():
	add_to_group("player")
	print("Игрок добавлен в группу player")
	
	setup_attack_area()
	setup_pickup_area()
	setup_ui()
	
	print("AttackArea найден: ", attack_area != null)
	print("AttackCollision найден: ", attack_collision != null)

func setup_attack_area():
	if attack_collision:
		attack_collision.disabled = true
	if attack_area:
		attack_area.monitoring = true
		attack_area.collision_layer = 1
		attack_area.collision_mask = 1
		attack_area.position.x = 1.0

func setup_pickup_area():
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

func setup_ui():
	if ui:
		ui.setup_hearts(max_health)
		ui.update_hearts(player_health)

# ============================================
# 4. ДВИЖЕНИЕ
# ============================================

func _physics_process(delta):
	var direction = get_movement_direction()
	
	apply_movement(direction)
	apply_gravity(delta)
	update_animations(direction)
	rotate_player(direction)
	
	handle_jump()
	handle_attack()
	handle_pickup()
	
	move_and_slide()

func get_movement_direction() -> int:
	if Input.is_action_pressed("a"):
		return -1
	elif Input.is_action_pressed("d"):
		return 1
	return 0

func apply_movement(direction: int):
	if is_attacking:
		velocity.x = direction * speed * 0.5
	else:
		velocity.x = direction * speed

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

# ============================================
# 5. АНИМАЦИИ И ПОВОРОТ
# ============================================

func update_animations(direction: int):
	if is_attacking:
		return
	
	if not is_on_floor():
		if animated_sprite.sprite_frames.has_animation("jump"):
			animated_sprite.play("jump")
	elif direction != 0:
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
	else:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

func rotate_player(direction: int):
	if direction != 0:
		# Поворот на 180 градусов для левого направления, 0 для правого
		if direction < 0:
			rotation.y = PI   # Смотрит влево
		else:
			rotation.y = 0    # Смотрит вправо

# ============================================
# 6. АТАКА
# ============================================

func handle_attack():
	if Input.is_action_just_pressed("m1") and can_attack and not is_attacking:
		perform_attack()

func perform_attack():
	print("=== АТАКА ===")
	can_attack = false
	is_attacking = true
	
	play_attack_animation()
	enable_attack_collision()
	
	await get_tree().create_timer(0.25).timeout
	
	deal_damage_to_enemies()
	
	await get_tree().create_timer(0.25).timeout
	
	disable_attack_collision()
	is_attacking = false
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func play_attack_animation():
	var anim_name = "attack_weapon" if has_weapon else "attack"
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

func enable_attack_collision():
	if attack_collision:
		attack_collision.disabled = false

func disable_attack_collision():
	if attack_collision:
		attack_collision.disabled = true

func deal_damage_to_enemies():
	var bodies = attack_area.get_overlapping_bodies() if attack_area else []
	
	for body in bodies:
		if body.has_method("take_damage"):
			print("Наношу урон ", current_damage)
			body.take_damage(current_damage)
			
			if has_weapon:
				consume_weapon_durability()

# ============================================
# 7. ОРУЖИЕ
# ============================================

func handle_pickup():
	if Input.is_action_just_pressed("e") and nearby_weapon and not has_weapon:
		pickup_weapon(nearby_weapon)
		nearby_weapon.queue_free()
		nearby_weapon = null

func pickup_weapon(weapon):
	if has_weapon:
		return
	
	has_weapon = true
	weapon_damage = weapon.damage
	weapon_durability = weapon.max_durability
	weapon_name = weapon.weapon_name
	current_damage = weapon_damage
	
	print("Подобрано оружие: ", weapon_name)

func consume_weapon_durability():
	weapon_durability -= 1
	print("Оружие: ", weapon_name, ", осталось ударов: ", weapon_durability)
	
	if weapon_durability <= 0:
		break_weapon()

func break_weapon():
	has_weapon = false
	current_damage = base_damage
	print("Оружие сломалось!")

# ============================================
# 8. ЗОНА ПОДБОРА
# ============================================

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

# ============================================
# 9. ЗДОРОВЬЕ И СМЕРТЬ
# ============================================

func take_damage(amount):
	player_health -= amount
	print("Игрок получил урон ", amount, ", осталось здоровья: ", player_health)
	
	if ui:
		ui.update_hearts(player_health)
	
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

# ============================================
# 10. ПАУЗА
# ============================================

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
		pause_menu.visible = false
	else:
		get_tree().paused = true
		pause_menu.visible = true
