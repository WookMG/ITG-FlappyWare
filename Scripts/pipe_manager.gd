extends Node2D

#Pipeset scene for easy loading
var pipe_set = preload("res://Scenes/pipe_set.tscn")
var y_threshold = 200

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_spawn_pipe_timeout() -> void:
	if Global.current_state == Global.States.Playing:
		var pipe_set_instance = pipe_set.instantiate()
		var y_offset = RandomNumberGenerator.new().randf_range(-y_threshold, y_threshold)
		pipe_set_instance.position.y += y_offset
		add_child(pipe_set_instance)
