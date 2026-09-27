extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var collision_shape_2d: CollisionShape2D = $Floor/CollisionShape2D

const PLAYERSCALE: float = 0.5

var defaultPlayerY: int = 160
var playerNodes: Array[LobbyBird]
var red: Color = Color(1.0, 0.323, 0.361, 1.0)
var blue: Color = Color(0.084, 0.321, 0.655, 1.0)
var green: Color = Color(0.42, 0.963, 0.444, 1.0)
var yellow: Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	#Floor placement
	collision_shape_2d.global_position = Vector2(get_viewport().get_visible_rect().size.x/2, get_viewport().get_visible_rect().size.y + 10)
	collision_shape_2d.scale = Vector2(get_viewport().get_visible_rect().size.x, 5)

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	if node is LobbyBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
		
		node.scale = node.scale * PLAYERSCALE
		
		#set player color
		if numberOfPlayers == 1:
			setBirdColor(node, yellow)
		elif numberOfPlayers == 2:
			setBirdColor(node, red)
		elif numberOfPlayers == 3:
			setBirdColor(node, green)
		elif numberOfPlayers == 4:
			setBirdColor(node, blue)
		
		#set player location
		var divisionLength: float = get_viewport().get_visible_rect().size.x / 4
		node.global_position.y = defaultPlayerY
		node.global_position.x = (numberOfPlayers) * divisionLength - divisionLength/2

func setBirdColor(node: LobbyBird, color: Color) -> void:
	node.find_child("Sprite2D").modulate = color
