class_name DefaultPlayerModels
extends Sprite2D

@export var slot: int = 0
@export var texture_list: Array[Texture2D] = []
@export var body_list: Array[Node2D] = []

var body: Node2D
var alive: bool = true

func _ready() -> void:
	apply_model()

func apply_model() -> void:
	if slot < 1 or slot > texture_list.size() or slot > body_list.size(): return
	
	if alive: texture = texture_list[slot - 1] #Alive sprites
	else: texture = texture_list[slot + 3] #Dead sprites
	
	body = body_list[slot - 1]
	show_body()
	
	if slot == 2: offset = Vector2(1.25, 1.5)
	if slot == 3: offset = Vector2(1.5, -1.5)

func show_body() -> void:
	body.show()
	
func hide_body() -> void:
	body.hide()
