extends Node2D

#Pipeset scene for easy loading
@onready var pipe_set: Node2D = $pipe_set
@onready var toppipe: Area2D = $pipe_set/toppipe
@onready var bottompipe: Area2D = $pipe_set/bottompipe

var y_threshold = 200
var x_offset = 2000

func _ready() -> void:
	toppipe.set_multiplayer_authority(1)
	bottompipe.set_multiplayer_authority(1)

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server(): return
	pipe_set.position.x -= Global.bird_speed
	rpc("sync_pipe_position", pipe_set.position)

@rpc("authority", "call_remote", "unreliable")
func sync_pipe_position(pos: Vector2) -> void:
	pipe_set.position = pos
	
func _on_spawn_pipe_timeout() -> void:
	if !multiplayer.is_server(): return
	var y_offset = RandomNumberGenerator.new().randf_range(-y_threshold, y_threshold)
	pipe_set.position.y += y_offset
	pipe_set.position.x = x_offset
	
	rpc("sync_pipe_position", pipe_set.position)
