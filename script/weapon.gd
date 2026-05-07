extends Area3D

@export var weapon_name = "Pipe"
@export var damage = 25
@export var max_durability = 5

@onready var animated_sprite = $AnimatedSprite3D

func _ready():
	add_to_group("weapons")
	monitoring = true
	monitorable = true
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")
		animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	print("Оружие создано: ", weapon_name)
