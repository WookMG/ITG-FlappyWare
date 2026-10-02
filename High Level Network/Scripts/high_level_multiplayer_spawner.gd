# high_level_multiplayer_spawner.gd
class_name HighLevelMultiplayerSpawner
extends MultiplayerSpawner

@onready var players: Node2D = $"../Players"
@export var network_player: PackedScene

func _ready() -> void:
	if multiplayer.is_server():
		spawn_player(1)
	multiplayer.peer_connected.connect(spawn_player)

func spawn_player(id: int) -> void:
	if multiplayer.get_peers().size() == 4: # lobby full
		HighLevelNetworkHandler.disconnect_reason = "Lobby Full"
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	
	var player: Node = network_player.instantiate()
	player.name = str(id) # name the player by their their UID
	
	#assign player to node slot
	var openSlot : Node
	for child in get_node(spawn_path).get_children():
		if child.get_child_count() == 0:
			openSlot = child
			break
	openSlot.call_deferred("add_child", player)
