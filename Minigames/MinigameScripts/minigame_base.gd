class_name MinigameBase
extends Node2D
## Base script for minigame root nodes.
## Scene requirements:
##   - a MultiplayerSpawner node named "MultiplayerSpawner" (plain node, NO script,
##     empty Auto Spawn List, Spawn Path set to where players should be added)
##   - a Node2D named "Start Positions" with one Marker2D child per slot (p1..p4)
## Set `player_scene` in the Inspector on each minigame root.

const MAX_SLOTS := 4
const PITCHES: Array[float] = [1.0, 1.5, 0.5, 0.7]

@export var player_scene: PackedScene
@export var player_scale: float = 0.5
@export var load_timeout: float = 10.0

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawn_points_container: Node2D = $"Start Positions"

var spawn_points: Array[Vector2] = []
var _switching := false


func _ready() -> void:
	assert(player_scene != null, "MinigameBase: assign player_scene in the Inspector")

	# Must be ready on EVERY peer before any spawn happens.
	for i in mini(spawn_points_container.get_child_count(), MAX_SLOTS):
		spawn_points.append(spawn_points_container.get_child(i).global_position)
	while spawn_points.size() < MAX_SLOTS:
		push_warning("MinigameBase: fewer than 4 start positions, padding with (0,0)")
		spawn_points.append(Vector2.ZERO)

	spawner.spawn_function = _spawn_player  # all peers

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_spawn_when_ready()
	else:
		HighLevelNetworkHandler.client_loaded.rpc_id(1)


# ---------------------------------------------------------------- spawning

func _spawn_when_ready() -> void:
	var waited := 0.0
	while waited < load_timeout:
		var all_loaded := true
		for id in multiplayer.get_peers():
			if !HighLevelNetworkHandler.loaded_peers.has(id):
				all_loaded = false
				break
		if all_loaded:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()

	for slot in HighLevelNetworkHandler.connectedPlayerIDs.size():
		var id := HighLevelNetworkHandler.connectedPlayerIDs[slot]
		if id != HighLevelNetworkHandler.EMPTY_SLOT and multiplayer.get_peers().has(id.to_int()):
			spawner.spawn({"id": id.to_int(), "slot": slot})

	_on_all_players_loaded()


# Runs on every peer with the same data, so every peer builds identical players.
func _spawn_player(data: Dictionary) -> Node:
	var p := player_scene.instantiate() as Node2D
	p.name = str(data.id)  # name BEFORE entering the tree (authority comes from it)
	p.position = spawn_points[data.slot]
	apply_player_properties(p, data.slot)
	_on_player_created(p, data)
	return p


## Applies slot-based look (scale, color, flap pitch). Safe if a child is missing.
func apply_player_properties(node: Node2D, slot: int) -> void:
	assert(slot >= 0 and slot < MAX_SLOTS, "slot %d out of bounds (0,3)" % slot)
	node.scale *= player_scale

	var colors: Array[Color] = [Global.p1Color, Global.p2Color, Global.p3Color, Global.p4Color]
	var sprite := node.find_child("Sprite2D", true, false)
	if sprite:
		sprite.modulate = colors[slot]

	var flap := node.find_child("Flap", true, false)
	if flap:
		flap.pitch_scale = PITCHES[slot]


# ----------------------------------------------------------- disconnects

func _on_peer_disconnected(peer_id: int) -> void:
	var container := spawner.get_node(spawner.spawn_path)
	var player := container.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()  # spawner despawns it on clients too
	_on_player_left(peer_id)


# ------------------------------------------------------- switching games

## Server only. Moves everyone to another minigame. Slots, colors and pitch
## carry over because connectedPlayerIDs lives in the autoload and the next
## minigame re-applies them at spawn.
func change_minigame(path: String) -> void:
	if !multiplayer.is_server() or _switching:
		return
	_switching = true
	HighLevelNetworkHandler.switch_minigame.call_deferred(path)


## Server only. Sends everyone back to the lobby.
func return_to_lobby() -> void:
	if !multiplayer.is_server() or _switching:
		return
	_switching = true
	HighLevelNetworkHandler.return_to_lobby.call_deferred()


# ------------------------------------------------- hooks for subclasses

## Runs on every peer, before the player enters the tree.
func _on_player_created(_player: Node2D, _data: Dictionary) -> void:
	pass

## Runs on the server after a player's node is freed.
func _on_player_left(_peer_id: int) -> void:
	pass

## Runs on the server once every client has loaded the scene (or the timeout
## hit) and spawning has been requested. Safe point to start server-driven
## things that RPC to clients.
func _on_all_players_loaded() -> void:
	pass
