extends MinigameBase

@onready var countdown: Control = $Countdown

var alive_players: Array[int] = []
var dead_players: Array[int] = []

func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		var player = player_root.get_node(str(id))
		player.died.connect(_player_died)
		alive_players.append(id)
		players.append(player.get_path())

func _end_minigame():
	super._end_minigame()
	var player_win_info: Dictionary = {}
	for id in alive_players:
		player_win_info[str(id)] = true
	for id in dead_players:
		player_win_info[str(id)] = false
	SceneManager.end_minigame.rpc(players, player_win_info)

func _on_all_players_loaded() -> void:
	countdown.play()
	await get_tree().create_timer(2.1).timeout
	super._on_all_players_loaded()

func _player_died(id: int):
	if !NetworkHandler.is_server: return
	print("Player ", id, " has died")
	alive_players.erase(id)
	dead_players.append(id)
	
	if alive_players.size() <= 0: _end_minigame()
