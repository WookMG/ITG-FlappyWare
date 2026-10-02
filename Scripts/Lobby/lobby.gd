class_name Lobby
extends Node2D

@onready var multiplayer_spawner: HighLevelMultiplayerSpawner = $MultiplayerSpawner
@onready var players_container: Node = $Players

const PLAYERSCALE: float = 0.5
var defaultPlayerY: float

func _ready() -> void:
	defaultPlayerY = get_viewport().get_visible_rect().size.y / 2
	if NetworkHandler.is_server:
		for id in NetworkHandler.connected_players:
			_spawn_player(id)
	
	NetworkHandler.player_connected.connect(_spawn_player)
	NetworkHandler.player_disconnected.connect(_despawn_player)

func _spawn_player(id: int) -> void:
	var player_scene = preload("res://Scenes/Lobby/lobby_bird.tscn")
	var player = player_scene.instantiate()
	
	player.name = str(id)
	player.set_multiplayer_authority(id)
	
	players_container.add_child(player, true)
	set_bird_properties(player, NetworkHandler.connected_players[str(id)].slot)

func _despawn_player(id: int) -> void:
	var player = players_container.get_node_or_null(str(id))
	if player:
		player.queue_free()

func set_bird_properties(node: LobbyBird, slot: int) -> void:
	assert(slot >= 1 && slot <= 4, "slot \"" + str(slot) + "\"out of bounds (1,4)")
	node.scale = node.scale * PLAYERSCALE
	set_bird_pitch(node, slot)
	set_bird_location(node, slot)

func set_bird_pitch(node: LobbyBird, slot: int) -> void:
	var sound = node.find_child("Flap")
	if slot == 1:
		sound.pitch_scale = 1
	elif slot == 2:
		sound.pitch_scale = 1.5
	elif slot == 3:
		sound.pitch_scale = 0.5
	elif slot == 4:
		sound.pitch_scale = 0.7

func set_bird_location(node: LobbyBird, slot: int):
	var divisionLength: float = get_viewport().get_visible_rect().size.x / 4
	node.global_position.y = defaultPlayerY
	node.global_position.x = (slot * divisionLength) - divisionLength/2

#Return Pipe
func _onReturnPipeEntered(body: Node2D) -> void:
	
	if !NetworkHandler.is_server: return
	if body is LobbyBird:
		
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
	if body is LobbyBird:
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
	if body is LobbyBird:
		body.hit_pipe()
		set_bird_location(body, NetworkHandler.connected_players[body.name].slot)
