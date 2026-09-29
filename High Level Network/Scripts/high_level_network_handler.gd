extends Node

signal playerIDsUpdated

const IP_ADDRESS: String = "localhost"
const PORT: int = 42069
const MAX_PLAYERS: int = 4
const EMPTY_SLOT := "<null>"

var peer: ENetMultiplayerPeer
var connectedPlayerIDs: Array[String]
var disconnect_reason: String = ""
var loaded_peers: Array[int] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	connectedPlayerIDs.resize(MAX_PLAYERS)
	connectedPlayerIDs.fill(EMPTY_SLOT)

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_disconnected(peer_id: int) -> void:
	#print("autoload peer_disconnected: ", peer_id)
	removePlayerID(str(peer_id))

func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_server_disconnected() -> void:
	if disconnect_reason == "":
		disconnect_reason = "Lost connection to the host."
	multiplayer.multiplayer_peer = null
	connectedPlayerIDs.fill(EMPTY_SLOT)
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

func addPlayerID(id: String) -> void:
	if !multiplayer.is_server():
		return
	var i := connectedPlayerIDs.find(EMPTY_SLOT)
	if i == -1:
		return  # lobby full
	connectedPlayerIDs[i] = id
	_server_update_ids()

func removePlayerID(id: String) -> void:
	#print("removePlayerID: ", id)
	if not multiplayer.is_server():
		return
	var i := connectedPlayerIDs.find(id)
	if i == -1:
		return
	connectedPlayerIDs[i] = EMPTY_SLOT
	_server_update_ids()

func _server_update_ids() -> void:
	playerIDsUpdated.emit()
	sync_player_ids.rpc(connectedPlayerIDs)

@rpc("authority", "call_remote", "reliable")
func sync_player_ids(ids: Array) -> void:
	connectedPlayerIDs.assign(ids)
	playerIDsUpdated.emit()

@rpc("authority", "call_remote", "reliable")
func server_closing() -> void:
	disconnect_reason = "The host closed the game."
	multiplayer.multiplayer_peer = null
	connectedPlayerIDs.fill(EMPTY_SLOT)
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

func start_minigame(path: String) -> void:
	if !multiplayer.is_server():
		return
	peer.refuse_new_connections = true 
	#^ Set it back to false when you return to the lobby, or players can never join again
	loaded_peers.clear()
	load_minigame.rpc(path)

@rpc("authority", "call_local", "reliable")
func load_minigame(path: String) -> void:
	get_tree().change_scene_to_file(path)

# each client calls this from the minigame's _ready
@rpc("any_peer", "call_remote", "reliable")
func client_loaded() -> void:
	loaded_peers.append(multiplayer.get_remote_sender_id())

#Call return_to_lobby() from the server when the round ends, 
#using call_deferred if you're inside a physics callback.
func return_to_lobby() -> void: #
	if !multiplayer.is_server():
		return
	peer.refuse_new_connections = false
	loaded_peers.clear()
	load_minigame.rpc("res://Scenes/lobby.tscn")
