class_name MinigameBase
extends Node2D
## Base script for minigame root nodes.
## Scene requirements:
##   - a Node2D named "Spawns" with one Marker2D per slot (named 1 through 4 respectively) 
##     inside of the players node
##   - a MultiplayerSpawner node named "MultiplayerSpawner" (NO script, specific player 
##     scene set in the Auto Spawn List, Spawn Path set to  the "Players" Node)
##   

signal start_minigame()

@export var load_timeout: float = 2.0
@export var minigame_time: float = 10.0
@export var player_scene: PackedScene

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players

const MAX_SLOTS := 4

var players: Array[NodePath] = []
var minigame_timer: Timer

func _ready() -> void:
	# Must be ready on EVERY peer before any spawn happens.
	multiplayer_spawner.spawn_function = _spawn_player_with_data
	create_timer()
	
	if !NetworkHandler.is_server: 
		NetworkHandler.client_loaded.rpc_id(1, multiplayer.get_unique_id())
		return
	
	NetworkHandler.player_disconnected.connect(_despawn_player)
	NetworkHandler.client_loaded.rpc_id(1, 1)
	_spawn_when_ready()

# ---------------------------------------------------------------- spawning

func create_timer() -> void:
	minigame_timer = Timer.new()
	add_child(minigame_timer)
	minigame_timer.wait_time = minigame_time
	minigame_timer.one_shot = true
	minigame_timer.timeout.connect(_end_minigame)

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
		_spawn_player(id)
	_on_all_players_loaded()

# Runs on every peer with the same data, so every peer builds identical players.
func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		players.append(player_root.get_node(str(id)).get_path())

func _spawn_player_with_data(data: Dictionary) -> Node:
	var player_root: Node2D = player_scene.instantiate()
	var player: MultiplayerBase = player_root.get_node("Player")
	
	player.name = str(data["id"])
	player.slot = data["slot"]
	player.player_name = data["name"]
	start_minigame.connect(player._start_minigame)
	
	player.set_multiplayer_authority(data["id"])
	
	return player_root

# ----------------------------------------------------------- disconnects

func _despawn_player(id: int) -> void:
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()
	_on_player_left(id)

# ------------------------------------------------------- switching games

func _end_minigame() -> void:
	if !NetworkHandler.is_server: return
	minigame_timer.stop()
	# Create your own in your own minigame and call super() at the top

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
	# super() AFTER you've implemented your own code
	start.rpc()
	minigame_timer.start()

@rpc("authority", "call_local", "reliable")
func start() -> void:
	start_minigame.emit()
