class_name MinigameBase
extends Node2D
## Base script for minigame root nodes.
## Scene requirements:
##   - a MultiplayerSpawner node named "MultiplayerSpawner" (plain node, NO script,
##     empty Auto Spawn List, Spawn Path set to where players should be added)
##   - a Node2D named "Spawns" with one Marker2D child per slot (p1..p4) inside of the
##     players node
##   - a Timer named "MinigameTimer" that we will use to know when minigames are done

signal start_minigame()

@export var load_timeout: float = 2.0

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players
@onready var minigame_timer: Timer = $MinigameTimer

const MAX_SLOTS := 4

var players: Array[NodePath] = []

func _ready() -> void:
	# Must be ready on EVERY peer before any spawn happens.
	multiplayer_spawner.spawn_function = _spawn_player_with_data
	
	if !NetworkHandler.is_server: 
		NetworkHandler.client_loaded.rpc_id(multiplayer.get_unique_id())
		return
	
	NetworkHandler.player_disconnected.connect(_despawn_player)
	NetworkHandler.client_loaded.rpc_id(1)
	_spawn_when_ready()

# ---------------------------------------------------------------- spawning

func _spawn_when_ready() -> void:
	var waited = 0.0
	while waited < load_timeout:
		var all_loaded = true
		for id in NetworkHandler.connected_players:
			all_loaded = !NetworkHandler.loaded_players.has(int(id))
			if !all_loaded: break
		if all_loaded: break
		await get_tree().process_frame
		waited += get_process_delta_time()

	for id in NetworkHandler.loaded_players:
		_spawn_player(id)

	_on_all_players_loaded()

# Runs on every peer with the same data, so every peer builds identical players.
func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		players.append(player_root.get_node(str(id)).get_path())

func _spawn_player_with_data(data: Dictionary) -> Node:
	var player_scene = preload("res://Scenes/Lobby/multiplayer_bird.tscn")
	var player_root: Node2D = player_scene.instantiate()
	var player : MultiplayerBird = player_root.get_node("Multiplayer Bird")
	
	player.name = str(data["id"])
	player.slot = data["slot"]
	player.player_name = data["name"]
	player.game_mode = player.Gamemode #TODO ADD GAMEMODE HERE .Gamemode
	#start_minigame.connect(player.) #TODO ADD CUSTOM START FUNCTION FROM BIRD HERE
	
	player.set_multiplayer_authority(data["id"])
	
	return player_root

# ----------------------------------------------------------- disconnects

func _despawn_player(id: int) -> void:
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()
	_on_player_left(id)

# ------------------------------------------------------- switching games

func _end_minigame():
	if !NetworkHandler.is_server: return
	minigame_timer.stop()
	var player_win_info: Dictionary = {}
	
	#TODO send this info to scene manager to play win animations etc.

# ------------------------------------------------- hooks for subclasses

## Runs on every peer, before the player enters the tree.
func _on_player_created(id: Node2D, _data: Dictionary) -> void:
	pass

## Runs on the server after a player's node is freed.
func _on_player_left(id: int) -> void:
	pass

## Runs on the server once every client has loaded the scene (or the timeout
## hit) and spawning has been requested. Safe point to start server-driven
## things that RPC to clients.
func _on_all_players_loaded() -> void:
	pass

@rpc("authority", "call_local", "reliable")
func start():
	start_minigame.emit()
