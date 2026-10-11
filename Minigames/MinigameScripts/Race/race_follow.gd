extends Camera2D

var player: CharacterBody2D = null
var nodes: Array[Node]

func _ready() -> void:
	nodes = get_children()

func _process(delta: float) -> void:
	if player and is_instance_valid(player): 
		for node in nodes:
			node.global_position.x = player.global_position.x
