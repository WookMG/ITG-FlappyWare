extends Node

signal clientConnected(peer)

const IP_ADDRESS: String = "localhost"
const PORT: int = 42069
const MAX_PLAYERS: int = 4

var peer: ENetMultiplayerPeer
var connectedPlayerIDs: Array[String]

func _ready() -> void:
	connectedPlayerIDs.resize(MAX_PLAYERS)
	connectedPlayerIDs.fill(str(null))

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer

func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	clientConnected.emit(peer)
