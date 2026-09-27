extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

const PLAYERSCALE: float = 0.5

var defaultPlayerY: int = 160
var playerNodes: Array[LobbyBird]

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	if node is LobbyBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
		
		node.scale = node.scale * PLAYERSCALE
		
		var divisionLength: float = get_viewport().get_visible_rect().size.x / numberOfPlayers
		
		#set player locations
		node.global_position.y = defaultPlayerY
		for i in numberOfPlayers:
			playerNodes[i].global_position.x = i * divisionLength + divisionLength/2

#func _physics_process(delta: float) -> void:
	#bounce players off bottom of screen
	#for i in playerNodes.size():
		#if playerNodes[i].global_position.y >= get_viewport().get_visible_rect().size.y && playerNodes[i].velocity.y >= 0:
			#playerNodes[i].velocity.y = - abs(playerNodes[i].velocity.y)
