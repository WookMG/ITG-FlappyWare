extends Node2D

var main = preload("res://Scenes/main.tscn")

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
	playerNodes.resize(HighLevelNetworkHandler.connectedPlayerIDs.size())
	
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(peer_disconnected)
	else: 
		multiplayer.server_disconnected.connect(on_server_disconnected)

func _on_child_exiting_tree(node: Node) -> void:
	var i := playerNodes.find(node)
	if i != -1:
		playerNodes[i] = null
		HighLevelNetworkHandler.connectedPlayerIDs[i] = null

func _on_child_entered_tree(node: Node) -> void:
	var currentNumberOfPlayers: int = 0
	if node is LobbyBird:
		#place player in empty slot
		var slot = HighLevelNetworkHandler.connectedPlayerIDs.find(node.get_multiplayer_authority())
		
		for i in playerNodes.size():
			if playerNodes[i] == null:
				playerNodes[i] = node
				playerIDs[i] = node.get_multiplayer_authority()
				slot = i
				break
		
		setBirdProperties(node, slot)

func setBirdProperties(node: LobbyBird, slot: int) -> void:
	assert(slot >= 0 && slot <= 3, "slot \"" + str(slot) + "\"out of bounds (0,3)")
	node.scale = node.scale * PLAYERSCALE
	setBirdLocation(node, slot)
	setBirdColor(node, slot)
	setBirdPitch(node, slot)

func setBirdPitch(node: LobbyBird, slot: int) -> void:
	var sound = node.find_child("Flap")
	if slot == 0:
		sound.pitch_scale = 1
	elif slot == 1:
		sound.pitch_scale = 1.5
	elif slot == 2:
		sound.pitch_scale = 0.5
	elif slot == 3:
		sound.pitch_scale = 0.7

func setBirdColor(node: LobbyBird, slot: int) -> void:
	var sprite: Sprite2D = node.find_child("Sprite2D")
	if slot == 0:
		sprite.modulate = p1Color
	elif slot == 1:
		sprite.modulate = p2Color
	elif slot == 2:
		sprite.modulate = p3Color
	elif slot == 3:
		sprite.modulate = p4Color

func setBirdLocation(node: LobbyBird, slot: int):
	var divisionLength: float = get_viewport().get_visible_rect().size.x / 4
	slot += 1
	node.global_position.y = defaultPlayerY
	node.global_position.x = (slot * divisionLength) - divisionLength/2

#Return Pipe
func _onReturnPipeEntered(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is LobbyBird:
		send_player_to_menu.call_deferred(body.name.to_int())

#Start Pipe
func _onStartPipeEntered(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is LobbyBird:
		send_player_to_menu.call_deferred(body.name.to_int())

#func send_players_to_minigame()

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
