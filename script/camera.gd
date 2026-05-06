extends Camera3D

var target: Node3D = null
var follow_speed = 5.0
var offset = Vector3(0, 1.5, 5)

func _physics_process(delta):
	if target == null:
		target = get_tree().get_first_node_in_group("player")
		return

	var target_position = target.global_position + offset

	global_position = global_position.lerp(target_position, follow_speed * delta)
