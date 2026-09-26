extends Node2D

@onready var playerSpawner = $MultiplayerSpawner

const defaultPlayerY: int = 160

var playerNodes: Array[MultiplayerBird]

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	if node is MultiplayerBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
	
	var divisionLength: float
	var divisionPositions: Array[float]
	if numberOfPlayers != 0:
		divisionLength = get_viewport().size.x / numberOfPlayers
		for i in numberOfPlayers:
			playerNodes[i].global_position = Vector2(i * divisionLength + divisionLength/2, defaultPlayerY)
			divisionPositions[i] = i * divisionLength
	
	#use divisionPositions to create visible divisions between the players at each division position
