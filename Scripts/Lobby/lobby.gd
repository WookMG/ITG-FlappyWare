extends Node2D

var defaultPlayerY: int = 160

var playerNodes: Array[LobbyBird]

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	if node is LobbyBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
		
		var divisionLength: float = get_viewport().get_visible_rect().size.x / numberOfPlayers
		
		node.global_position.y = defaultPlayerY
		
		for i in numberOfPlayers:
			playerNodes[i].global_position.x = i * divisionLength + divisionLength/2
			print(1)
