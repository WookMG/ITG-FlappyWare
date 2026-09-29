extends Node2D

@export var player_scene: PackedScene
@export var spawn_points: Array[Vector2]
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	spawner.spawn_function = _spawn_player   # set on ALL peers
	if multiplayer.is_server():
		_spawn_when_ready()
	else:
		HighLevelNetworkHandler.client_loaded.rpc_id(1)

func _spawn_when_ready() -> void:
	var ids: Array[int] = []
	for id in HighLevelNetworkHandler.connectedPlayerIDs:
		if id != "" and id.to_int() != 1:
			ids.append(id.to_int())
	while !ids.all(func(i): return HighLevelNetworkHandler.loaded_peers.has(i)):
		await get_tree().process_frame
	for slot in HighLevelNetworkHandler.connectedPlayerIDs.size():
		var id := HighLevelNetworkHandler.connectedPlayerIDs[slot]
		if id != "":
			spawner.spawn({"id": id.to_int(), "slot": slot})

func _spawn_player(data: Dictionary) -> Node:
	var p := player_scene.instantiate()
	p.name = str(data.id)                    # name BEFORE it enters the tree
	p.position = spawn_points[data.slot]
	return p
