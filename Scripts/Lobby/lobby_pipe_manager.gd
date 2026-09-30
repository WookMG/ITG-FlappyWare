extends Node2D

#Pipeset scene for easy loading
@onready var pipe_set: Node2D = $pipe_set
@onready var toppipe: StaticBody2D = $pipe_set/toppipe
@onready var bottompipe: StaticBody2D = $pipe_set/bottompipe

var y_threshold = 200
var x_offset = 2000

func _ready() -> void:
	toppipe.set_multiplayer_authority(1)
	bottompipe.set_multiplayer_authority(1)

func _physics_process(delta: float) -> void:
	pipe_set.position.x -= Global.bird_speed

func _on_spawn_pipe_timeout() -> void:
	var y_offset = RandomNumberGenerator.new().randf_range(-y_threshold, y_threshold)
	pipe_set.position.y += y_offset
	pipe_set.position.x = x_offset
