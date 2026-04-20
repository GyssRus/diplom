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
	# НЕ отключаем коллизию навсегда!
	# attack_collision.disabled = true  ← УБРАТЬ ЭТУ СТРОКУ
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	add_to_group("enemies")
	print("Враг создан! Здоровье: ", health)

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = direction * speed
	else:
		velocity.x = 0
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()

func _on_attack_area_body_entered(body):
	print("В AttackArea вошло: ", body.name)
	
	if body.is_in_group("player") and can_attack:
		print("Атакуем игрока!")
		can_attack = false
		
		# Наносим урон
		body.take_damage(attack_damage)
		
		# Ждём перезарядку
		await get_tree().create_timer(1.0).timeout
		can_attack = true

func take_damage(amount):
	health -= amount
	print("Враг получил урон ", amount, ", осталось ", health)
	
	# Визуальный эффект
	if has_node("MeshInstance3D"):
		var material = $MeshInstance3D.get_active_material(0)
		if material:
			material.albedo_color = Color(1, 0, 0)
			await get_tree().create_timer(0.1).timeout
			material.albedo_color = Color(1, 0.5, 0.5)
	
	if health <= 0:
		print("Враг умер!")
		queue_free()
