extends MinigameBase

signal fishJump

@onready var sun: Node2D = $"Sun Container"
@onready var fish_container: Node2D = $"Fish Container"

var sunRot: float = 0
const CYCLE_TIME: float = 80
var timer: Timer

@export var minWait: float = 1.5
@export var maxWait: float = 5
@export var endGameDelay: float = 2
var timeBeforeFish: Timer

var winning_players: Array[int] = [] #TODO assign
var losing_players: Array[int] = [] #TODO assign

func _spawn_player(id: int) -> void:
		var player_root: Node2D = multiplayer_spawner.spawn({"id": id,
							"slot": NetworkHandler.connected_players[str(id)].slot,
							"name": NetworkHandler.connected_players[str(id)].player_name})
		var player = player_root.get_node(str(id))
		player.won.connect(_player_won)
		losing_players.append(id)
		players.append(player.get_path())
		
		fishJump.connect(Callable(fish_container.get_child(player.slot - 1), "_fishJump"))

func _ready() -> void:
	super._ready()
	var waitTime: float = randf_range(minWait, maxWait)
	#get_tree().root.find_child("minigame_time").wait_time = waitTime + endGameDelay
	
	#Fish
	timeBeforeFish = Timer.new()
	timeBeforeFish.wait_time = waitTime
	timeBeforeFish.one_shot = true
	add_child(timeBeforeFish)
	timeBeforeFish.timeout.connect(_timeBeforeFish_timeout) #Timer is started in _on_all_players_loaded()
	
	
	#Sun
	timer = Timer.new()
	timer.wait_time = CYCLE_TIME
	timer.one_shot = false
	sun.add_child(timer)
	timer.start()

func _end_minigame():
	super._end_minigame()
	var player_win_info: Dictionary = {}
	for id in winning_players:
		player_win_info[str(id)] = true
	for id in losing_players:
		player_win_info[str(id)] = false
	SceneManager.end_minigame.rpc(players, player_win_info)

func _on_all_players_loaded() -> void:  # server only, from MinigameBase
	super._on_all_players_loaded()
	timeBeforeFish.start()

func _physics_process(_delta: float) -> void:
	rotateSun()
	if !multiplayer.is_server():
		return

func rotateSun() -> void:
	$"Sun Container/Rays1".rotation = sunRot
	$"Sun Container/Rays2".rotation = -sunRot + 45
	var numerator = CYCLE_TIME - timer.time_left
	sunRot = (numerator/CYCLE_TIME) * (180/PI)

func _player_won(id: int) -> void:
	if !NetworkHandler.is_server: return
	print("Player ", id, " has won")
	losing_players.erase(id)
	winning_players.append(id)
	
	if winning_players.size() <= 0: _end_minigame()

func _timeBeforeFish_timeout() -> void:
	emit_signal("fishJump")
	
