extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var pipe_container: Node2D = $"Pipe Container"

const PLAYERSCALE: float = 0.5

var defaultPlayerY: float
var playerNodes: Array[LobbyBird]
#Player colors
var p1Color: Color = Color(1.0, 1.0, 1.0, 1.0) #default color
var p2Color: Color = Color(1.0, 0.323, 0.361, 1.0)
var p3Color: Color = Color(0.42, 0.963, 0.444, 1.0)
var p4Color: Color = Color(0.084, 0.321, 0.655, 1.0)

func _ready() -> void:
	defaultPlayerY = get_viewport().get_visible_rect().size.y / 2

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	if node is LobbyBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
		
		node.scale = node.scale * PLAYERSCALE
		
		#set player color
		if numberOfPlayers == 1:
			setBirdColor(node, p1Color)
		elif numberOfPlayers == 2:
			setBirdColor(node, p2Color)
		elif numberOfPlayers == 3:
			setBirdColor(node, p3Color)
		elif numberOfPlayers == 4:
			setBirdColor(node, p4Color)
		
		#set player location
		var divisionLength: float = get_viewport().get_visible_rect().size.x / 4
		node.global_position.y = defaultPlayerY
		node.global_position.x = (numberOfPlayers) * divisionLength - divisionLength/2

func setBirdColor(node: LobbyBird, color: Color) -> void:
	node.find_child("Sprite2D").modulate = color
