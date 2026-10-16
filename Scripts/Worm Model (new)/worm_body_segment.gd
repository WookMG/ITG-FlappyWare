extends Node2D

@onready var worm_body: AnimatedSprite2D = $"Worm Body"
@onready var caterpillar_body: AnimatedSprite2D = $"Caterpillar Body"
@onready var snail_body: AnimatedSprite2D = $"Snail Body"
@onready var maggot_body: AnimatedSprite2D = $"Maggot Body"

var wormType: String = "<null>"
var leader: Node
var segmentNumber: int = 0
var parentScale: float

var followSpeed: float

func _ready() -> void:
	leader = get_parent()
	assert(leader, "Worm Body Segment was never assigned a leader node")
	wormType = leader.wormType
	assert(wormType != "<null>", "Worm Body Segment was never assigned a worm type")
	
	top_level = true
	z_as_relative = true
	z_index = leader.z_index - 1
	
	parentScale = leader.scale.x
	scale = leader.scale
	
	#hide all children
	for child in get_children():
		child.hide()
	
	followSpeed = leader.followSpeed
	swapBodyType(wormType, segmentNumber)
	global_position = global_position + Vector2(-0.1,0.1)


func _physics_process(delta: float) -> void:
	
	follow(delta)

func swapBodyType(type: String, segment: int) -> void:
	var frame: int = segment
	match type:
		"Earth Worm":
			worm_body.show()
			if frame == 1:
				worm_body.frame = frame
			else:
				frame = 0
				worm_body.frame = frame
		"Caterpillar":
			caterpillar_body.show()
			frame = 0
			caterpillar_body.frame = frame
		"Snail":
			snail_body.show()
			if frame == 1:
				snail_body.frame = frame
			else:
				frame = 0
				snail_body.frame = frame
		"Maggot":
			maggot_body.show()
			frame = 0
			maggot_body.frame = frame
		_: push_error("\"", type, "\" does not exist as a current type")

func follow(delta: float) -> void:
	var parentPosition = leader.global_position
	var toParent = (parentPosition - global_position).normalized()
	var minDistance = (parentScale * 8) * toParent
	global_position = lerp(global_position, parentPosition - minDistance, delta * followSpeed)
