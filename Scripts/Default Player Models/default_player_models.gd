class_name DefaultPlayerModels
extends Sprite2D


var body: Node2D
@export var slot: int = 0
@export var texture_list: Array[Texture2D] = [
	preload("res://Assets/Sprites/Worm/head.png"),
	preload("res://Assets/Sprites/Caterpillar/head.png"),
	preload("res://Assets/Sprites/Snail/head.png"),
	preload("res://Assets/Sprites/Maggot/head.png")]
	
@export var body_list: Array[Node2D] = []

func _ready() -> void:
	apply_model()

func apply_model() -> void:
	if slot < 1 or slot > texture_list.size():
		return

	texture = texture_list[slot - 1]

	if slot <= body_list.size():
		body = body_list[slot - 1]
		body.show()
