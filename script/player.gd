extends CharacterBody3D

var speed = 5.0
var jump_velocity = 4.5
var gravity = 15.0
var can_attack = true

@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/AttackCollision

func _ready():
	# Создаём зону атаки программно (чтобы не было ошибок)
	setup_attack_area()

func setup_attack_area():
	# Создаём Area3D
	attack_area = Area3D.new()
	attack_area.name = "AttackArea"
	add_child(attack_area)
	
	
	# Включаем мониторинг
	attack_area.monitoring = true
	attack_collision.disabled = true

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
	can_attack = false
	attack_collision.disabled = false
	
	await get_tree().physics_frame
	
	var bodies = attack_area.get_overlapping_bodies()
	print("Найдено тел: ", bodies.size())
	
	for body in bodies:
		if body != self and body.has_method("take_damage"):
			print("Атака по ", body.name)
			body.take_damage(10)
	
	await get_tree().create_timer(0.2).timeout
	attack_collision.disabled = true
	await get_tree().create_timer(0.5).timeout
	can_attack = true
