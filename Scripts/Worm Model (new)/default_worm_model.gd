extends Node2D

@onready var earth_worm_head: AnimatedSprite2D = $"Earth Worm Head"
@onready var caterpillar_head: AnimatedSprite2D = $"Caterpillar Head"
@onready var snail_head: AnimatedSprite2D = $"Snail Head"
@onready var maggot_head: AnimatedSprite2D = $"Maggot Head"

@onready var segmentScene: PackedScene = preload("uid://dxsxapjkbm41m")

@export_enum("Earth Worm", "Caterpillar", "Snail", "Maggot") var wormType: String = "<null>"
@export var bodySegments: int

var followSpeed = 50

var headNode: AnimatedSprite2D
var slot: int #left over from multiplayer_base.gd

func _physics_process(delta: float) -> void:
	global_position.x += 100*delta
	global_position.y += 1*delta

func _ready() -> void:
	match slot:
		1: wormType = "Earth Worm"
		2: wormType = "Caterpillar"
		3: wormType = "Snail"
		4: wormType = "Maggot"
	assert(wormType != "<null>", "Worm Model was never assigned a worm type")
	
	#hide all children
	for child in get_children():
		child.hide()
	
	#show head and select head node
	match wormType:
		"Earth Worm":
			headNode = earth_worm_head
			earth_worm_head.show()
		"Caterpillar":
			headNode = caterpillar_head
			caterpillar_head.show()
		"Snail":
			headNode = snail_head
			snail_head.show()
		"Maggot":
			headNode = maggot_head
			maggot_head.show()
	
	var leader = self
	for i in bodySegments:
		var segment = segmentScene.instantiate()
		segment.leader = leader
		segment.segmentNumber = (i + 1)
		leader.add_child(segment)
		leader = segment

func _swapHeadType(state: String) -> void:
	match state:
		"default":
			headNode.frame = 0
		"dead":
			headNode.frame = 1
		_:
			push_error("State: \"", state, "\" is not defined in _swapHeadType()")
