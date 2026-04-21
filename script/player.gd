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

@onready var attack_area = $MeshInstance3D/AttackArea
@onready var attack_collision = $MeshInstance3D/AttackArea/AttackCollision
@onready var mesh = $MeshInstance3D

func _ready():
	add_to_group("player")
	print("Игрок добавлен в группу player")
	
	# Создаём зону подбора оружия
	var pickup_area = Area3D.new()
	pickup_area.name = "PickupArea"
	add_child(pickup_area)
	
	var pickup_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.5, 2.5, 2.5)
	pickup_collision.shape = box_shape
	pickup_area.add_child(pickup_collision)
	
	# Настройка слоёв коллизий
	pickup_area.collision_layer = 1
	pickup_area.collision_mask = 1
	
	# Подключаем сигналы
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	pickup_area.area_exited.connect(_on_pickup_area_exited)
	
	# Включаем мониторинг
	pickup_area.monitoring = true
	pickup_area.monitorable = true
	
	print("PickupArea создана! Размер: 2.5 x 2.5 x 2.5")
	
	if attack_collision:
		attack_collision.disabled = true
	if attack_area:
		attack_area.monitoring = true
	
	print("AttackArea найден: ", attack_area != null)
	print("AttackCollision найден: ", attack_collision != null)

func _physics_process(delta):
	var direction = 0
	
	# Временная отладка для клавиши E
	if Input.is_action_just_pressed("e"):
		print("Клавиша E НАЖАТА!")
		print("nearby_weapon: ", nearby_weapon)
		print("has_weapon: ", has_weapon)
	
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
	
	# Подбор оружия по клавише E
	if Input.is_action_just_pressed("e") and nearby_weapon and not has_weapon:
		pickup_weapon(nearby_weapon)
		nearby_weapon.queue_free()
		nearby_weapon = null
	
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
			
			# Расход прочности оружия
			if has_weapon:
				weapon_durability -= 1
				print("Оружие: ", weapon_name, ", осталось ударов: ", weapon_durability)
				
				if weapon_durability <= 0:
					break_weapon()
	
	await get_tree().create_timer(0.2).timeout
	
	if attack_collision:
		attack_collision.disabled = true
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func pickup_weapon(weapon):
	# Если уже есть оружие — не подбираем новое
	if has_weapon:
		print("У вас уже есть оружие!")
		return
	
	# Подбираем оружие
	has_weapon = true
	weapon_damage = weapon.damage
	weapon_durability = weapon.max_durability
	weapon_name = weapon.weapon_name
	
	# Меняем текущий урон
	current_damage = weapon_damage
	
	print("Подобрано оружие: ", weapon_name)
	print("Урон: ", weapon_damage, ", Прочность: ", weapon_durability)

func break_weapon():
	has_weapon = false
	current_damage = base_damage
	weapon_damage = 0
	weapon_durability = 0
	
	print("Оружие сломалось! Урон вернулся к ", base_damage)

func _on_pickup_area_entered(area):
	print("[PickupArea] Вошла область: ", area.name)
	print("  area.get_parent(): ", area.get_parent().name)
	print("  area.get_parent().get_groups(): ", area.get_parent().get_groups())
	
	# Само оружие — это родитель области (CollisionShape3D)
	var weapon = area.get_parent()
	
	# Проверяем, есть ли у оружия группа "weapons"
	if weapon.is_in_group("weapons"):
		nearby_weapon = weapon
		print("  nearby_weapon УСТАНОВЛЕН! Оружие: ", weapon.weapon_name)
		print("  Рядом оружие! Нажмите E чтобы подобрать")
	else:
		# Если родитель не в группе, может быть, само оружие — это area?
		if area.is_in_group("weapons"):
			nearby_weapon = area
			print("  nearby_weapon УСТАНОВЛЕН (через area)! Оружие: ", area.weapon_name)
			print("  Рядом оружие! Нажмите E чтобы подобрать")
		else:
			print("  Оружие НЕ в группе weapons!")

func _on_pickup_area_exited(area):
	var weapon = area.get_parent()
	if weapon.is_in_group("weapons") and nearby_weapon == weapon:
		nearby_weapon = null
		print("Оружие вышло из зоны подбора")
	elif area.is_in_group("weapons") and nearby_weapon == area:
		nearby_weapon = null
		print("Оружие вышло из зоны подбора (через area)")

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
