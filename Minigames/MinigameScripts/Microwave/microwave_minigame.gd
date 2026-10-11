extends MinigameBase

signal openDoor

@onready var spawns: Node2D = $Players/Spawns

var winning_players: Array[int] = []
var losing_players: Array[int] = []

func _ready() -> void:
	super._ready()

func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		var player = player_root.get_node(str(id))
		player.breakOut.connect(_player_won)
		losing_players.append(id)
		players.append(player.get_path())
		
		openDoor.connect(Callable(spawns.get_child(player.slot - 1).find_child("Microwave"), "_openDoor"))

func _on_all_players_loaded() -> void:  # server only, from MinigameBase
	super._on_all_players_loaded()

func _player_won(id: int) -> void:
	if !NetworkHandler.is_server: return
	print("Player ", id, " has won")
	losing_players.erase(id)
	winning_players.append(id)
	
	openDoor.emit()
	
	if winning_players.size() <= 0: _end_minigame()

func _end_minigame():
	super._end_minigame()
	var player_win_info: Dictionary = {}
	for id in winning_players:
		player_win_info[str(id)] = true
	for id in losing_players:
		player_win_info[str(id)] = false
	SceneManager.end_minigame.rpc(players, player_win_info)
