extends Area3D

@export var weapon_name = "Pipe"
@export var damage = 25
@export var max_durability = 5

func _ready():
	add_to_group("weapons")
	print("Оружие создано: ", weapon_name)
	print("Позиция оружия: ", global_position)
	print("Группы: ", get_groups())
	
	# Включаем мониторинг
	monitoring = true
	monitorable = true
