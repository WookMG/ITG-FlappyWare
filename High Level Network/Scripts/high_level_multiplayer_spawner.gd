# high_level_multiplayer_spawner.gd
extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)

func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return
	HighLevelNetworkHandler.addPlayerID(str(id))
	spawn_bird(id)

func spawn_bird(id: int) -> void:
	if !multiplayer.is_server(): return
	var container := get_node(spawn_path)
	if container.has_node(str(id)):
		return  # already exists
	var player: Node = network_player.instantiate()
	player.name = str(id)
	container.call_deferred("add_child", player)

# for players who are already connected (e.g. returning from the minigame)
func spawn_existing_players() -> void:
	if !multiplayer.is_server(): return
	for id_str in HighLevelNetworkHandler.connectedPlayerIDs:
		if id_str == HighLevelNetworkHandler.EMPTY_SLOT:
			continue
		spawn_bird(id_str.to_int())
