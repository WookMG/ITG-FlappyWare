extends RigidBody2D

@export var init_vel: int = 1000

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	apply_central_impulse(direction * init_vel)
	rotation = direction.angle()

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > 0.1:
		rotation = linear_velocity.angle()
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is MultiplayerBase:
		body.die.rpc()
	queue_free()
