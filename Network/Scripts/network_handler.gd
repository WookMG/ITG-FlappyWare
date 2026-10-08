extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_established
signal connection_failed

const DEFAULT_IP_ADDRESS: String = "localhost"
const DEFAULT_PORT: int = 42069
const MAX_PLAYERS: int = 4
var MAINMENU = preload("uid://vxlj6cuch30x")

var peer: ENetMultiplayerPeer
var is_server: bool = false
var connected_players: Dictionary = {}
var loaded_players: Array[int] = []

var disconnect_reason: String = ""

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
	print("FPS: ", Engine.get_frames_per_second())

func start_server(player_name: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		push_error("Failed to create server: %s" % error_string(error))
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	
	if player_name == "": player_name = "Host"
	connected_players['1'] = PlayerInfo.new(1, player_name, true)
	connected_players['1'].slot = 1
	print("Server started on port %d" % port)
	return OK

func start_client(player_name: String, address: String = DEFAULT_IP_ADDRESS, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		push_error("Failed to create client: %s" % error_string(error))
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	
	await multiplayer.connected_to_server
	submit_player_name.rpc_id(1, player_name)
	
	return OK

@rpc("any_peer", "reliable")
func submit_player_name(player_name: String) -> void:
	if !is_server: return
	
	var id = multiplayer.get_remote_sender_id()
	if connected_players.has(str(id)):
		if player_name == "": player_name = "player_" + str(id)
		connected_players[str(id)].set_player_name(player_name)
		player_connected.emit(id)

func leave_game() -> void:
	if peer:
		peer.close()
		peer = null
	
	multiplayer.multiplayer_peer = null
	is_server = false
	connected_players.clear()
	
	disconnect_reason = ""
	get_tree().change_scene_to_packed(MAINMENU)

func disconnect_game() -> void:
	if peer:
		peer.close()
		peer = null
	
	multiplayer.multiplayer_peer = null
	is_server = false
	connected_players.clear()
	
	if disconnect_reason == "":
		disconnect_reason = "Lost connection to the host."
	get_tree().change_scene_to_packed(MAINMENU)

func _on_peer_connected(id: int) -> void:
	print("Peer connected: %d" % id)
	connected_players[str(id)] = PlayerInfo.new(id, "Player_%d" % id)
	connected_players[str(id)].set_slot()

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %d" % id)
	connected_players.erase(str(id))
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	print("Connected to server. My ID: %d" % multiplayer.get_unique_id())
	connection_established.emit()

func _on_connection_failed() -> void:
	print("Connection failed")
	disconnect_game()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("Server disconnected")
	disconnect_game()

@rpc("authority", "call_remote", "reliable")
func server_closing() -> void:
	disconnect_reason = "The host closed the game."
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_packed(MAINMENU)

@rpc("any_peer", "call_local", "reliable")
func client_loaded(id: int) -> void:
	if id not in loaded_players:
		loaded_players.append(id)
