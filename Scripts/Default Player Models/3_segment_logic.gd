extends Node2D

@export var waitFrames: int = 2
@export var bodyResetSpeed: int = 3
@export var bodyPieceRestDistanceMultiplier: float = 4.5
var bufferPositions1: Array[Vector2]
var bufferPositions2: Array[Vector2]
var headLastFrame: Vector2
@onready var head: DefaultPlayerModels = $".."


func _ready() -> void:
	bufferPositions1.resize(waitFrames)
	bufferPositions1.fill(head.global_position)
	bufferPositions2.resize(waitFrames)
	bufferPositions2.fill(head.global_position)

func _physics_process(_delta: float) -> void:
	follow()

func follow() -> void:
	if head.global_position == headLastFrame: 
		
		if !head.flip_h:
			if $Body1.global_position.x >= head.global_position.x - (bodyPieceRestDistanceMultiplier * head.scale.x):
				$Body1.global_position.x -= bodyResetSpeed
			if $Body2.global_position.x >= $Body1.global_position.x - (bodyPieceRestDistanceMultiplier * head.scale.x):
				$Body2.global_position.x -= 2*bodyResetSpeed
		else:
			if $Body1.global_position.x <= head.global_position.x + (bodyPieceRestDistanceMultiplier * head.scale.x):
				$Body1.global_position.x += bodyResetSpeed
			if $Body2.global_position.x <= $Body1.global_position.x + (bodyPieceRestDistanceMultiplier * head.scale.x):
				$Body2.global_position.x += 2*bodyResetSpeed
		
		headLastFrame = head.global_position
		return
	
	$Body1.global_position = bufferPositions1.pop_front()
	bufferPositions1.push_back(head.global_position)
	$Body2.global_position = bufferPositions2.pop_front()
	bufferPositions2.push_back($Body1.global_position)
	
	headLastFrame = head.global_position
