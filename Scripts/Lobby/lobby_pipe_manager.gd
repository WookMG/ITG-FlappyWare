extends Node2D

#Pipeset scene for easy loading
var pipe_set = null
var y_threshold = 200
var x_offset = 2000

func _on_spawn_pipe_timeout() -> void:
	var y_offset = RandomNumberGenerator.new().randf_range(-y_threshold, y_threshold)
	pipe_set.position.y += y_offset
	pipe_set.position.x = x_offset
