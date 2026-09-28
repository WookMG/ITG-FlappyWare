extends Node2D

var main = preload("res://Scenes/main.tscn")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var pipe_container: Node2D = $"Pipe Container"

const PLAYERSCALE: float = 0.5

var defaultPlayerY: float
var playerNodes: Array[LobbyBird]
var playerIDs: Array[int]

#Player colors
var p1Color: Color = Color(1.0, 1.0, 1.0, 1.0) #default color
var p2Color: Color = Color(1.0, 0.323, 0.361, 1.0)
var p3Color: Color = Color(0.42, 0.963, 0.444, 1.0)
var p4Color: Color = Color(0.084, 0.321, 0.655, 1.0)

func _ready() -> void:
	defaultPlayerY = get_viewport().get_visible_rect().size.y / 2
	playerNodes.resize(HighLevelNetworkHandler.MAX_PLAYERS)
	playerIDs.resize(HighLevelNetworkHandler.MAX_PLAYERS)

func peer_disconnected(peer_id: int):
	var playerNode: LobbyBird
	for i in playerNodes.size():
		if playerNodes[i] != null && playerIDs[i] == peer_id:
			playerNode = playerNodes[i]
			playerNodes[i] = null
			playerIDs[i] = -1
			break
		
	if playerNode != null:
		playerNode.queue_free()

func _on_child_entered_tree(node: Node) -> void:
	var currentNumberOfPlayers: int = 0
	if node is LobbyBird:
		#place player in empty slot
		var slot = -1
		for i in playerNodes.size():
			if playerNodes[i] == null:
				playerNodes[i] = node
				playerIDs[i] = node.get_multiplayer_authority()
				slot = i
				break
		
		node.scale = node.scale * PLAYERSCALE
		setBirdLocation(node, slot)
		#set player color, and pitch
		if slot == 0:
			setBirdColor(node, p1Color)
		elif slot == 1:
			setBirdColor(node, p2Color)
			node.find_child("Flap").pitch_scale = 1.5
		elif slot == 2:
			setBirdColor(node, p3Color)
			node.find_child("Flap").pitch_scale = 0.5
		elif slot == 3:
			setBirdColor(node, p4Color)
			node.find_child("Flap").pitch_scale = 0.7

func setBirdColor(node: LobbyBird, color: Color) -> void:
	node.find_child("Sprite2D").modulate = color

func setBirdLocation(node: LobbyBird, slot: int):
	var divisionLength: float = get_viewport().get_visible_rect().size.x / 4
	slot += 1
	node.global_position.y = defaultPlayerY
	node.global_position.x = (slot * divisionLength) - divisionLength/2

#Return Pipe
func _on_area_2d_body_entered(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is LobbyBird:
		change_scene_for_client.call_deferred(body.name.to_int())

# On the server
@rpc("authority", "call_local")
func change_scene_for_client(client_id: int) -> void:
	if client_id == multiplayer.get_unique_id():
		load_scene()
	else:
		rpc_id(client_id, "load_scene")
	# give the client time to leave before removing its bird on the server
	await get_tree().create_timer(0.2).timeout
	peer_disconnected(client_id)

# On the client
@rpc("authority", "call_local")
func load_scene() -> void:
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")
	queue_free()  # Lobby lives under /root, so the scene change won't remove it
