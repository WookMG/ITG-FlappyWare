# high_level_multiplayer_spawner.gd
class_name HighLevelMultiplayerSpawner
extends MultiplayerSpawner

@export var network_player: PackedScene


func _ready() -> void:
	if multiplayer.is_server():
		spawn_player(1)
	multiplayer.peer_connected.connect(spawn_player)

# spawner
func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return
	if !HighLevelNetworkHandler.addPlayerID(str(id)):
		multiplayer.multiplayer_peer.disconnect_peer(id)  # lobby full
		return
	spawn_bird(id)

func spawn_bird(id: int) -> void:
	if !multiplayer.is_server(): return
	var player: Node = network_player.instantiate()
	player.name = str(id) # name the player by their their UID
	get_node(spawn_path).call_deferred("add_child", player)
