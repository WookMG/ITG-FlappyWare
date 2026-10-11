extends MinigameBase

@onready var follow_player: Node2D = $FollowPlayer

var players_not_finished: Array[int] = []
var players_finished: Array[int] = []

func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		var player = player_root.get_node(str(id))
		player.finished.connect(_player_finished)
		player.set_alpha()
		players_not_finished.append(id)
		players.append(player.get_path())
		if is_multiplayer_authority(): follow_player.player = player

func _end_minigame():
	super._end_minigame()
	var player_win_info: Dictionary = {}
	for id in players_finished:
		player_win_info[str(id)] = true
	for id in players_not_finished:
		player_win_info[str(id)] = false
	SceneManager.end_minigame.rpc(players, player_win_info)

func _on_all_players_loaded() -> void:
	await get_tree().create_timer(1.5).timeout
	print("3...")
	await get_tree().create_timer(.5).timeout
	print("2...")
	await get_tree().create_timer(.5).timeout
	print("1...")
	await get_tree().create_timer(.5).timeout
	print("Go!")
	
	super._on_all_players_loaded()

func _player_finished(id: int) -> void:
	if !NetworkHandler.is_server: return
	print("Player ", id, " has finished the race")
	players_finished.append(id)
	players_not_finished.erase(id)
	
	if players_finished.size() >= players.size(): _end_minigame()
