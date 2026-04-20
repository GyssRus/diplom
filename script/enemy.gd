extends CharacterBody3D

var health = 30
var speed = 2.0
var gravity = 15.0
var attack_damage = 10
var can_attack = true

@onready var attack_area = $AttackArea
@onready var attack_collision = $AttackArea/AttackCollision

var player = null

func _ready():
	attack_collision.disabled = true
	attack_area.body_entered.connect(_on_attack_area_body_entered)
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
	else:
		velocity.x = 0
	
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and can_attack:
		can_attack = false
		attack_collision.disabled = false
		
		body.take_damage(attack_damage)
		print("Враг атаковал!")
		
		await get_tree().create_timer(0.2).timeout
		attack_collision.disabled = true
		await get_tree().create_timer(1.0).timeout
		can_attack = true

func take_damage(amount):
	health -= amount
	print("Враг получил урон ", amount, ", осталось ", health)
	
	# Краснеем при ударе
	if has_node("MeshInstance3D"):
		var material = $MeshInstance33D.get_active_material(0)
		if material:
			material.albedo_color = Color(1, 0, 0)
			await get_tree().create_timer(0.1).timeout
			material.albedo_color = Color(1, 0.5, 0.5)
	
	if health <= 0:
		print("Враг умер!")
		queue_free()
