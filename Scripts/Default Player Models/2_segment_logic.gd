extends Node2D

@export var waitFrames: int = 3
var bufferPositions1: Array[Vector2]
var headLastFrame: Vector2

func _ready() -> void:
	bufferPositions1.resize(waitFrames)
	bufferPositions1.fill($"..".global_position)
	headLastFrame = $"..".global_position

func _physics_process(delta: float) -> void:
	follow()

func follow() -> void:
	if $"..".global_position == headLastFrame: return
	$Body1.global_position = bufferPositions1.pop_front()
	bufferPositions1.push_back($"..".global_position)
	headLastFrame = $"..".global_position
