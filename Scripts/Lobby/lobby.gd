class_name Lobby
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players

func _ready() -> void:
	multiplayer_spawner.spawn_function = _spawn_player_with_data
	
	if !NetworkHandler.is_server: return
	for id in NetworkHandler.connected_players:
		_spawn_player(int(id))
	
	NetworkHandler.player_connected.connect(_spawn_player)
	NetworkHandler.player_disconnected.connect(_despawn_player)

func _spawn_player(id: int) -> void:
	multiplayer_spawner.spawn({"id": id, "slot": NetworkHandler.connected_players[str(id)].slot})

func _spawn_player_with_data(data: Dictionary) -> Node:
	var player_scene = preload("res://Scenes/Lobby/multiplayer_bird.tscn")
	var player: MultiplayerBird = player_scene.instantiate()
	
	player.name = str(data["id"])
	player.slot = data["slot"]
	player.set_multiplayer_authority(data["id"])
	
	return player

func _despawn_player(id: int) -> void:
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()

#Return Pipe
func _onReturnPipeEntered(body: Node2D) -> void:
	if !NetworkHandler.is_server: return
	if body is MultiplayerBird:
		
		var id = int(body.name)
		if id == 1:
			#rpc can't be called with only sercer :sob:
			NetworkHandler.leave_game()
		else:
			leave_lobby.rpc_id(id)

#Start Pipe
func _onStartPipeEntered(body: Node2D) -> void:
	var i = randi_range(0,0) #change range when more games added
	if !NetworkHandler.is_server: return
	if body is MultiplayerBird:
		print("WORKING ON THIS")

@rpc("authority", "reliable")
func leave_lobby() -> void:
	NetworkHandler.leave_game()
	
# disconnect player if they clsoe their window
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()

func _on_bird_collide(body: Node2D) -> void:
	if !NetworkHandler.is_server: return
	if body is MultiplayerBird:
		body.hit_pipe.rpc_id(int(body.name))
