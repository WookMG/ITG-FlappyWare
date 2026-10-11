extends Node2D

var player_to_follow: CharacterBody2D = null
var nodes: Array[Node]

func _ready() -> void:
	nodes = get_children()

func _process(delta: float) -> void:
	if player_to_follow and is_instance_valid(player_to_follow): 
		for node in nodes:
			node.global_position.x = player_to_follow.global_position.x

@rpc("authority", "call_local", "unreliable")
func set_player(id: int) -> void:
	var player = get_parent().get_node("Players").get_node_or_null(str(id)).get_node(str(id))
	if player: 
		player_to_follow = player
		print("PLAYER FOUND")
