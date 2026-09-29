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
	playerIDs.fill(-1)
	
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(peer_disconnected)
	else: 
		multiplayer.server_disconnected.connect(on_server_disconnected)

func _on_child_exiting_tree(node: Node) -> void:
	var i := playerNodes.find(node)
	if i != -1:
		playerNodes[i] = null
		playerIDs[i] = -1

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
		send_player_to_menu.call_deferred(body.name.to_int())

func send_player_to_menu(client_id: int) -> void:
	if client_id == multiplayer.get_unique_id():
		load_scene()
		return
	var player := get_node_or_null(str(client_id))
	if player:
		player.queue_free()
		await player.tree_exited
	rpc_id(client_id, "load_scene")
	await get_tree().create_timer(0.3).timeout
	multiplayer.multiplayer_peer.disconnect_peer(client_id, true)

@rpc("authority", "call_local")
func load_scene() -> void:
	if !multiplayer.is_server():
		multiplayer.multiplayer_peer = null  # fully disconnect from the host
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

# disconnect player if they clsoe their window
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()

func on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

func peer_disconnected(peer_id: int) -> void:
	var bird := get_node_or_null(str(peer_id))
	if bird:
		bird.queue_free()  # spawner despawns it on the remaining clients
