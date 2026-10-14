extends MinigameBase

@onready var spawns: Node2D = $Players/Spawns
@onready var microwave_door_close: AudioStreamPlayer = $MicrowaveDoorClose
@onready var microwave_door_open: AudioStreamPlayer = $MicrowaveDoorOpen
@onready var countdown: Control = $Countdown
@onready var microwave_beep: AudioStreamPlayer = $MicrowaveBeep
@onready var microwave_hum: AudioStreamPlayer = $MicrowaveHum
@onready var microwave_end_beep: AudioStreamPlayer = $MicrowaveEndBeep

var winning_players: Array[int] = []
var losing_players: Array[int] = []

var beeps: int

@export var doorIntegrity: int = 20

func _ready() -> void:
	super._ready()

func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		var player = player_root.get_node(str(id))
		losing_players.append(id)
		players.append(player.get_path())
		
		var microwave = spawns.get_child(player.slot - 1).find_child("Microwave")
		microwave.integrity = doorIntegrity
		player.integrity = doorIntegrity
		
		player.breakOut.connect(_player_won)
		player.hit.connect(Callable(microwave, "_redFlash"))

func _on_all_players_loaded() -> void:  # server only, from MinigameBase
	_start_minigame()
	super._on_all_players_loaded()

func _player_won(id: int) -> void:
	if !NetworkHandler.is_server: return
	print("Player ", id, " has won")
	losing_players.erase(id)
	winning_players.append(id)
	
	microwave_door_open.play()
	if losing_players.is_empty(): 
		get_tree().create_timer(1).timeout.connect(_end_minigame)

func _end_minigame():
	super._end_minigame()
	var player_win_info: Dictionary = {}
	for id in winning_players:
		player_win_info[str(id)] = true
	for id in losing_players:
		player_win_info[str(id)] = false
	
	microwave_hum.finished.disconnect(_hum)
	microwave_hum.stop()
	if !losing_players.is_empty():
		microwave_end_beep.finished.connect(endBeeps)
		beeps = 4
		endBeeps()
	SceneManager.end_minigame.rpc(players, player_win_info)

@rpc("any_peer", "call_remote", "unreliable")
func _hum() -> void:
	microwave_hum.stop()
	microwave_hum.play()

@rpc("any_peer", "call_remote", "unreliable")
func endBeeps() -> void:
	if beeps > 1:
		microwave_end_beep.play()
		beeps -= 1

@rpc("any_peer", "call_remote", "unreliable")
func _start_minigame() -> void:
	microwave_door_close.play()
	countdown.play()
	await get_tree().create_timer(1).timeout
	microwave_beep.play()
	await get_tree().create_timer(0.4).timeout
	microwave_beep.play()
	await get_tree().create_timer(0.4).timeout
	microwave_beep.play()
	await get_tree().create_timer(0.4).timeout
	microwave_beep.play()
	microwave_hum.play()
	microwave_hum.finished.connect(_hum)
