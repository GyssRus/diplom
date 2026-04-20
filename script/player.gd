extends CharacterBody3D

# Движение
var speed = 5.0
var jump_velocity = 4.5
var gravity = 15.0

# Бой
var base_damage = 10
var current_damage = 10
var attack_cooldown = 0.5
var can_attack = true

# Узлы (должны быть в сцене!)
@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/AttackCollision

func _ready():
	add_to_group("player")
	print("Игрок добавлен в группу player")
	
	# Настраиваем зону атаки
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
	print("Игрок получил урон ", amount)
