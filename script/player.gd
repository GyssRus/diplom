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

@onready var attack_area = $MeshInstance3D/AttackArea
@onready var attack_collision = $MeshInstance3D/AttackArea/AttackCollision
@onready var mesh = $MeshInstance3D

func _ready():
	add_to_group("player")
	print("Игрок добавлен в группу player")
	
	if attack_collision:
		attack_collision.disabled = true
	if attack_area:
		attack_area.monitoring = true
	
	print("AttackArea найден: ", attack_area != null)
	print("AttackCollision найден: ", attack_collision != null)

func _physics_process(delta):
	var direction = 0
	
	if Input.is_action_pressed("a"):
		direction = -1
	elif Input.is_action_pressed("d"):
		direction = 1
	
	velocity.x = direction * speed
	
	# Поворот персонажа
	if direction != 0:
		mesh.scale.x = -1 if direction < 0 else 1
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Атака
	if Input.is_action_just_pressed("m1") and can_attack:
		print("Атака")
		perform_attack()
	
	move_and_slide()

func perform_attack():
	print("=== АТАКА ===")
	can_attack = false
	
	if attack_collision:
		attack_collision.disabled = false
	
	await get_tree().physics_frame
	
	var bodies = []
	if attack_area:
		bodies = attack_area.get_overlapping_bodies()
	
	print("bodies.size(): ", bodies.size())
	
	for body in bodies:
		print("body.name: ", body.name)
		print("body.is_in_group('enemies'): ", body.is_in_group("enemies"))
		print("body.has_method('take_damage'): ", body.has_method("take_damage"))
		
		if body.has_method("take_damage"):
			print("Наношу урон ", current_damage)
			body.take_damage(current_damage)
	
	await get_tree().create_timer(0.2).timeout
	
	if attack_collision:
		attack_collision.disabled = true
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount):
	player_health -= amount
	print("Игрок получил урон ", amount, ", осталось здоровья: ", player_health)
	
	if mesh:
		var material = mesh.get_active_material(0)
		if material:
			var original_color = material.albedo_color
			material.albedo_color = Color(1, 1, 1)
			await get_tree().create_timer(0.1).timeout
			material.albedo_color = original_color
	
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
