extends Camera2D

var player: CharacterBody2D = null
func _process(delta: float) -> void:
	if player and is_instance_valid(player): global_position.x = player.global_position.x
