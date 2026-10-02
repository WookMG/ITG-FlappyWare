extends Node

var mainMenu = preload("res://Scenes/main_menu.tscn")


const IP_ADDRESS: String = "localhost"
const PORT: int = 42069
const MAX_PLAYERS: int = 4
const EMPTY_SLOT := "<null>"

var peer: ENetMultiplayerPeer
var disconnect_reason: String = ""

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_disconnected(peer_id: int) -> void:
	pass

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
	get_tree().change_scene_to_packed(mainMenu)

@rpc("authority", "call_remote", "reliable")
func server_closing() -> void:
	disconnect_reason = "The host closed the game."
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

func start_minigame(path: String) -> void:
	switch_minigame(path)

@rpc("authority", "call_local", "reliable")
func load_minigame(path: String) -> void:
	get_tree().change_scene_to_file(path)

#Call return_to_lobby() from the server when the round ends, 
#using call_deferred if you're inside a physics callback.
func return_to_lobby() -> void: #
	if !multiplayer.is_server():
		return
	peer.refuse_new_connections = false
	load_minigame.rpc("res://Scenes/lobby.tscn")

func switch_minigame(path: String) -> void:
	if !multiplayer.is_server():
		return
	if !ResourceLoader.exists(path):
		push_error("switch_minigame: no scene at " + path)
		return
	peer.refuse_new_connections = true
	load_minigame.rpc(path)
