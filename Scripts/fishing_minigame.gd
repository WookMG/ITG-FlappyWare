extends Node2D

@onready var playerSpawner = $MultiplayerSpawner
@onready var dividerSprite = $Divider

const defaultPlayerY: int = 160

var playerNodes: Array[MultiplayerBird]
var dividerCount: int = 0

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	#Working
	
	if node is MultiplayerBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
		
		var divisionLength: float = get_viewport().size.x / numberOfPlayers
		var dividerHeight: float = get_viewport().size.y / 2
		
		if dividerCount != numberOfPlayers:
			for i in numberOfPlayers:
				
				var newDiv = Sprite2D.new()
				newDiv.name = "Divider " + str(i)
				newDiv.position = Vector2(i * divisionLength, dividerHeight)
				newDiv.show()
				node.add_child(newDiv)
				print(newDiv.get_parent(), newDiv.name, newDiv.position)
				dividerCount += 1
		
		for i in numberOfPlayers:
			playerNodes[i].global_position = Vector2(i * divisionLength + divisionLength/2, defaultPlayerY)
	
