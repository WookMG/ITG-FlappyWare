# fishing_minigame.gd
extends MinigameBase

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
