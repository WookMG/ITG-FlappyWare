extends Node2D

var main = preload("res://Scenes/main.tscn")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var pipe_container: Node2D = $"Pipe Container"

const PLAYERSCALE: float = 0.5

var defaultPlayerY: float

#Player colors
var p1Color: Color = Color(1.0, 1.0, 1.0, 1.0) #default color
var p2Color: Color = Color(1.0, 0.323, 0.361, 1.0)
var p3Color: Color = Color(0.42, 0.963, 0.444, 1.0)
var p4Color: Color = Color(0.084, 0.321, 0.655, 1.0)

var playerNodes: Array[LobbyBird] # HighLevelNetworkHandler.connectedPlayerIDs are the connected player IDs

func _ready() -> void:
	playerNodes.resize(4)
	defaultPlayerY = get_viewport().get_visible_rect().size.y / 2
	
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(peer_disconnected)
	else: 
		multiplayer.server_disconnected.connect(on_server_disconnected)
	
	multiplayer.connected_to_server.connect(_clientConnected)

func _clientConnected() -> void:
	#print("client connected")
	pass

func _on_child_entered_tree(node: Node) -> void:
	if node is not LobbyBird:
		return
	var slot := HighLevelNetworkHandler.connectedPlayerIDs.find(str(node.name))
	while slot == -1:
		await HighLevelNetworkHandler.playerIDsUpdated
		if not is_instance_valid(node):
			return  # bird was freed while waiting
		slot = HighLevelNetworkHandler.connectedPlayerIDs.find(str(node.name))
	playerNodes[slot] = node
	setBirdProperties(node, slot)

func setBirdProperties(node: LobbyBird, slot: int) -> void:
	assert(slot >= 0 && slot <= 3, "slot \"" + str(slot) + "\"out of bounds (0,3)")
	node.scale = node.scale * PLAYERSCALE
	setBirdLocation(node, slot)
	setBirdColor(node, slot)
	setBirdPitch(node, slot)
	#print("properties set")

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
		var id := body.name.to_int()
		if id == multiplayer.get_unique_id():
			return  # the host never leaves the lobby
		send_player_to_menu.call_deferred(id)

#Start Pipe
func _onStartPipeEntered(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is LobbyBird:
		send_player_to_menu.call_deferred(body.name.to_int())

func send_players_to_minigame() -> void:
	pass

func send_player_to_menu(client_id: int) -> void:
	if !multiplayer.is_server() || client_id == multiplayer.get_unique_id():
		return
	if !multiplayer.get_peers().has(client_id):
		return

	# free the slot right away, don't wait for peer_disconnected
	var slot := HighLevelNetworkHandler.connectedPlayerIDs.find(str(client_id))
	if slot != -1:
		playerNodes[slot] = null
	HighLevelNetworkHandler.removePlayerID(str(client_id))

	var player := get_node_or_null(str(client_id))
	if player:
		player.queue_free()
		await player.tree_exited
	load_scene.rpc_id(client_id)
	await get_tree().create_timer(0.3).timeout
	if multiplayer.get_peers().has(client_id):
		multiplayer.multiplayer_peer.disconnect_peer(client_id, true)

@rpc("authority", "call_remote", "reliable")
func load_scene() -> void:
	HighLevelNetworkHandler.peer.close()
	multiplayer.multiplayer_peer = null  # only ever runs on clients now
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
	if bird == null:
		return
	var idx := playerNodes.find(bird)
	if idx != -1:
		playerNodes[idx] = null
	bird.queue_free()
