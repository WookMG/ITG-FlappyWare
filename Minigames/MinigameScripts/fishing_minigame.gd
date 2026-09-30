# fishing_minigame.gd
extends MinigameBase

@onready var sun: Node2D = $"Sun Container"
var rot: float = 0
const CYCLE_TIME: float = 80
var timer = Timer.new()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	body.inWater = true
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	body.inWater = false
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _ready() -> void:
	sun.global_position = $"Sun Container/Start Position".global_position
	
	timer.wait_time = CYCLE_TIME
	timer.one_shot = false
	sun.add_child(timer)
	timer.start()

func _physics_process(delta: float) -> void:
	$"Sun Container/Rays1".rotation = rot
	$"Sun Container/Rays2".rotation = -rot + 45
	var numerator = CYCLE_TIME - timer.time_left
	rot = (numerator/CYCLE_TIME) * (180/PI)
