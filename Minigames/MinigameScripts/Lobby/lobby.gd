class_name Lobby
extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players
@onready var game_settings: Control = $"Game Settings"

func _ready() -> void:
	multiplayer_spawner.spawn_function = _spawn_player_with_data
	
	if !NetworkHandler.is_server: return
	for id in NetworkHandler.connected_players:
		_spawn_player(int(id))
	
	NetworkHandler.player_connected.connect(_spawn_player)
	NetworkHandler.player_disconnected.connect(_despawn_player)

func _spawn_player(id: int) -> void:
		multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})

func _spawn_player_with_data(data: Dictionary) -> Node:
	var player_scene = preload("uid://lamy5h6tblh")
	var player_root: Node2D = player_scene.instantiate()
	var player : MultiplayerBase = player_root.get_node("Player")
	
	player.name = str(data["id"])
	player.slot = data["slot"]
	player.player_name = data["name"]
	player.set_multiplayer_authority(data["id"])
	
	return player_root

func _despawn_player(id: int) -> void:
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()

#Return Pipe
func _onReturnPipeEntered(body: Node2D) -> void:
	if !NetworkHandler.is_server: return
	if body is MultiplayerBase:
		
		var id = int(body.name)
		if id == 1:
			#rpc can't be called with only server :sob:
			NetworkHandler.leave_game()
		else:
			leave_lobby.rpc_id(id)

#Start Pipe
func _onStartPipeEntered(body: Node2D) -> void:
	if !NetworkHandler.is_server: return
	if body is MultiplayerBase:
		SceneManager.setPlaylist()
		SceneManager.start_next_minigame()
		#SceneManager.start_minigame("res://Minigames/MinigameScenes/GunGame/gun_minigame.tscn")
		#SceneManager.start_minigame("res://Minigames/MinigameScenes/Fishing/fishing_minigame.tscn")

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
	if body is MultiplayerBase:
		body.hit_pipe.rpc_id(int(body.name))
