extends Sprite2D

@onready var door: Sprite2D = $Door
@export var speed: float = 1
@export var resistance: float = 0.0075

var start: bool = false

func _physics_process(delta: float) -> void:
	if start:
		if door.scale.x > -0.3:
			door.scale.x -= delta * speed
			speed = sign(speed) * (abs(speed) - resistance)

func _openDoor() -> void:
	start = true
