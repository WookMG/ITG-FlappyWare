extends Node

signal playerIDsUpdated

const IP_ADDRESS: String = "localhost"
const PORT: int = 42069
const MAX_PLAYERS: int = 4

var peer: ENetMultiplayerPeer
var connectedPlayerIDs: Array[String]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	connectedPlayerIDs.resize(MAX_PLAYERS)
	connectedPlayerIDs.fill(str(null))

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

func addPlayerID(id: String) -> void:
	if !multiplayer.is_server():
		return
	var i := connectedPlayerIDs.find(str(null))
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
	connectedPlayerIDs[i] = str(null)
	_server_update_ids()

func _server_update_ids() -> void:
	playerIDsUpdated.emit()
	sync_player_ids.rpc(connectedPlayerIDs)

@rpc("authority", "call_remote", "reliable")
func sync_player_ids(ids: Array) -> void:
	connectedPlayerIDs.assign(ids)
	playerIDsUpdated.emit()
