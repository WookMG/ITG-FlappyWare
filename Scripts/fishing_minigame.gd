extends Node2D

@onready var playerSpawner = $MultiplayerSpawner
@onready var water: Sprite2D = $WaterContainer/Water
@onready var area_2d: Area2D = $WaterContainer/Water/Area2D

const DEFAULTPLAYERY: int = 160
const BUOYANCY: float = 120
const WATERSLOW: float = 0.7

var playerNodes: Array[MultiplayerBird]
var playersInWater: Array[MultiplayerBird]

func _on_child_entered_tree(node: Node) -> void:
	var numberOfPlayers: int
	
	if node is MultiplayerBird:
		playerNodes.push_back(node)
		numberOfPlayers = playerNodes.size()
		
		var divisionLength: float = get_viewport().get_visible_rect().size.x / numberOfPlayers
		
		for i in numberOfPlayers:
			playerNodes[i].global_position = Vector2(i * divisionLength + divisionLength/2, DEFAULTPLAYERY)


func _physics_process(delta: float) -> void:
	for i in playerNodes.size():
		if playerNodes[i].global_position.y >= get_viewport().get_visible_rect().size.y && playerNodes[i].velocity.y >= 0:
			playerNodes[i].velocity.y = - abs(playerNodes[i].velocity.y)
	
	for i in playersInWater.size():
		playersInWater[i].velocity.y += -BUOYANCY


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is MultiplayerBird:
		playersInWater.push_back(body)
		body.velocity.y = body.velocity.y * WATERSLOW


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is MultiplayerBird:
		for i in range(playersInWater.size()):
			if playersInWater[i] == body:
				playersInWater.remove_at(i)
				body.velocity.y = body.velocity.y * WATERSLOW
