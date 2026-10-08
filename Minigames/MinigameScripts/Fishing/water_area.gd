extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is MultiplayerBase:
		body.enteredWater()

func _on_body_exited(body: Node2D) -> void:
	if body is MultiplayerBase:
		body.exitedWater()
