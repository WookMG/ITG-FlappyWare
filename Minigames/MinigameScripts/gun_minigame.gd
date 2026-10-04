class_name GunMinigame
extends Node2D

signal start_minigame()

@export var load_timeout: float = 2.0

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players
@onready var minigame_timer: Timer = $MinigameTimer

const MAX_SLOTS := 4

var alive_players: Array[int] = []
var dead_players: Array[int] = []
var _switching := false

func _ready() -> void:
	# Must be ready on EVERY peer before any spawn happens.
	multiplayer_spawner.spawn_function = _spawn_player_with_data
	
	if !NetworkHandler.is_server:
		print("LOADED PLAYER WITH ID: ", multiplayer.get_unique_id())
		NetworkHandler.client_loaded.rpc_id(1, multiplayer.get_unique_id())
		return
	
	NetworkHandler.player_disconnected.connect(_despawn_player)
	NetworkHandler.loaded_players.clear() 
	NetworkHandler.client_loaded(1)
	_spawn_when_ready()

# ---------------------------------------------------------------- spawning

func _spawn_when_ready() -> void:
	var waited = 0.0
	while waited < load_timeout:
		
		var all_loaded = true
		for id in NetworkHandler.connected_players:
			all_loaded = NetworkHandler.loaded_players.has(int(id))
			if !all_loaded: break
		if all_loaded: break
		await get_tree().process_frame
		waited += get_process_delta_time()

	for id in NetworkHandler.loaded_players:
		alive_players.append(id)
		_spawn_player(id)

	_on_all_players_loaded()

# Runs on every peer with the same data, so every peer builds identical players.
func _spawn_player(id: int) -> void:
		multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})

func _spawn_player_with_data(data: Dictionary) -> Node:
	var player_scene = preload("res://Scenes/Lobby/multiplayer_bird.tscn")
	var player_root: Node2D = player_scene.instantiate()
	var player : MultiplayerBird = player_root.get_node("Multiplayer Bird")
	
	player.name = str(data["id"])
	player.slot = data["slot"]
	player.player_name = data["name"]
	player.game_mode = player.Gamemode.GUNGAME
	player.isFacingLeft = randf() > 0.5
	player.set_multiplayer_authority(data["id"])
	
	start_minigame.connect(player._start_gun_minigame)
	player.died.connect(_player_died)
	return player_root

# ----------------------------------------------------------- disconnects

func _despawn_player(id: int) -> void:
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()
	_on_player_left(id)

# ------------------------------------------------------- switching games

## Server only. Moves everyone to another minigame. Slots, colors and pitch
## carry over because connectedPlayerIDs lives in the autoload and the next
## minigame re-applies them at spawn.
func change_minigame(player_win_info: Dictionary) -> void:
	if !NetworkHandler.is_server or _switching: return
	_switching = true
	SceneManager.end_minigame(player_win_info)

## Server only. Sends everyone back to the lobby.
func return_to_lobby() -> void:
	if !NetworkHandler.is_server or _switching: return
	_switching = true
	SceneManager.start_minigame.call_deferred("res://Scenes/Lobby/lobby.tscn")

# ------------------------------------------------- hooks for subclasses

## Runs on the server after a player's node is freed.
func _on_player_left(id: int) -> void:
	pass

# ------------------------------------------------- minigame base functions

## Runs on the server once every client has loaded the scene (or the timeout
## hit) and spawning has been requested. Safe point to start server-driven
## things that RPC to clients.
func _on_all_players_loaded() -> void:
	await get_tree().create_timer(1.5).timeout
	print("3...")
	await get_tree().create_timer(.5).timeout
	print("2...")
	await get_tree().create_timer(.5).timeout
	print("1...")
	await get_tree().create_timer(.5).timeout
	print("Go!")
	
	start.rpc()
	minigame_timer.start()

@rpc("authority", "call_local", "reliable")
func start():
	start_minigame.emit()

func _player_died(id: int):
	if !NetworkHandler.is_server: return
	print("Player ", id, " has died")
	alive_players.erase(id)
	dead_players.append(id)
	
	if alive_players.size() <= 0: _end_minigame()

func _end_minigame():
	if !NetworkHandler.is_server: return
	minigame_timer.stop()
	var player_win_info: Dictionary = {}
	for id in alive_players:
		player_win_info[str(id)] = true
	for id in dead_players:
		player_win_info[str(id)] = false
	return_to_lobby()
	#TODO send this info to scene manager to play win animations etc.
