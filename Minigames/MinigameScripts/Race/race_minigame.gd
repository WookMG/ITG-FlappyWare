extends MinigameBase

@onready var follow_player: Node2D = $FollowPlayer
@onready var player_camera: Camera2D = $FollowPlayer/PlayerCamera
@onready var end_camera: Camera2D = $EndCamera
@onready var countdown: Control = $Countdown

var players_not_finished: Array[int] = []
var players_finished: Array[int] = []

func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		var player = player_root.get_node(str(id))
		player.finished.connect(_player_finished)
		players_not_finished.append(id)
		players.append(player.get_path())
		follow_player.set_player.rpc_id(id, id)

func _end_minigame():
	super._end_minigame()
	switch_cameras.rpc()
	var player_win_info: Dictionary = {}
	for id in players_finished:
		player_win_info[str(id)] = true
	for id in players_not_finished:
		player_win_info[str(id)] = false
	SceneManager.end_minigame.rpc(players, player_win_info)

func _on_all_players_loaded() -> void:
	countdown.play()
	await get_tree().create_timer(2.1).timeout
	super._on_all_players_loaded()

func _player_finished(id: int) -> void:
	if !NetworkHandler.is_server: return
	print("Player ", id, " has finished the race")
	players_finished.append(id)
	players_not_finished.erase(id)
	
	if players_finished.size() >= players.size(): _end_minigame()

@rpc ("authority", "call_local", "unreliable")
func switch_cameras():
	end_camera.enabled = true
	player_camera.enabled = false

func _on_pipe_body_entered(body: Node2D) -> void:
	if body is MultiplayerBase:
		body.hit.rpc()

func _on_finish_body_entered(body: Node2D) -> void:
	if body is MultiplayerBase:
		body.finish.rpc()
