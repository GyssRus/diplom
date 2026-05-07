extends CanvasLayer

var heart_full = preload("res://assets/UI/UI_TravelBook_IconHeart01a.png")
var heart_empty = preload("res://assets/UI/UI_TravelBook_IconHeart01i.png")
var heart_half = preload("res://assets/UI/UI_TravelBook_IconHeart01e.png") 
var heart_container: HBoxContainer

var heart_size = Vector2(53, 44)
var heart_spacing = 8
var heart_position = Vector2(10, 10)

func _ready():
	heart_container = HBoxContainer.new()
	heart_container.position = heart_position
	add_child(heart_container)

func setup_hearts(max_health: int):
	for child in heart_container.get_children():
		child.queue_free()
	
	# Создаём целые сердечки
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.texture = heart_full
		heart.custom_minimum_size = heart_size
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart_container.add_child(heart)
		
		if i < max_health - 1:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(heart_spacing, heart_size.y)
			heart_container.add_child(spacer)

func update_hearts(health: float):
	var full_hearts = floor(health)
	var has_half = (health - full_hearts) >= 0.5
	
	var heart_index = 0
	for child in heart_container.get_children():
		if child is TextureRect:
			if heart_index < full_hearts:
				child.texture = heart_full
			elif heart_index == full_hearts and has_half:
				child.texture = heart_half
			else:
				child.texture = heart_empty
			heart_index += 1
