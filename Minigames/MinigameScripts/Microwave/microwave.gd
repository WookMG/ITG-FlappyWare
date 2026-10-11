extends Node2D

@onready var door: Sprite2D = $Door
@onready var collision_shape_2d: CollisionShape2D = $"Collision Container/Top/CollisionShape2D"
@onready var color_rect: ColorRect = $ColorRect

@export var speed: float = 1
@export var resistance: float = 0.0075

var integrity: int = 1 #set by microwave_minigame.gd

var start: bool = false
var hit: bool = false

func _physics_process(delta: float) -> void:
	if integrity <= 0:
		color_rect.hide()
		openDoor(delta)
		collision_shape_2d.disabled = true
	
	if hit:
		door.modulate += Color(0, 0.2, 0.2, 0)
		if door.modulate == Color(1.0, 1.0, 1.0, 1.0):
			hit = false

func _redFlash() -> void:
	if integrity <= 0: return
	door.modulate = Color(1, 0.4, 0.4, 1.0)
	hit = true
	integrity -= 1

func openDoor(delta: float) -> void:
	if door.scale.x > -0.3:
		door.scale.x -= delta * speed
		speed = sign(speed) * (abs(speed) - resistance)
