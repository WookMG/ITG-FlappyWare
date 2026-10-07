extends MinigameBase

@onready var sun: Node2D = $"Sun Container"
@onready var fish_container: Node2D = $"Fish Container"

var sunRot: float = 0
const CYCLE_TIME: float = 80
var timer: Timer

@export var minWait: float = 1.5
@export var maxWait: float = 5
@export var endGameDelay: float = 2
var timeBeforeFish: Timer

const ALL_FISH_INITIAL_VELOCITY: float = -6
const GRAVITY = 0.1
var allFishVelocity: Vector2

var fishRot = 0 
var fishRotVelocity = 0
@export var maxWiggleAngle: float = 45
var minWiggleAngle: float = 0
var wiggleAcceleration: float = 0.007

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

func _ready() -> void:
	super._ready()
	var waitTime: float = randf_range(minWait, maxWait)
	#get_tree().root.find_child("minigame_time").wait_time = waitTime + endGameDelay
	
	#Fish
	timeBeforeFish = Timer.new()
	timeBeforeFish.wait_time = waitTime
	timeBeforeFish.one_shot = true
	add_child(timeBeforeFish)
	#Timer is started in _on_all_players_loaded()
	
	maxWiggleAngle = maxWiggleAngle * (PI/180)
	minWiggleAngle = -maxWiggleAngle
	fishRot = maxWiggleAngle
	
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
	timeBeforeFish.start()
	super._on_all_players_loaded()

func _physics_process(_delta: float) -> void:
	rotateSun()
	if !multiplayer.is_server():
		return
	moveFish(fish_container)
	wiggleFish(fish_container)

func showRandomFish(node: Node) -> void:  # server only
	for child in node.get_children(false):
		var count: int = child.find_child("Sprites Container").get_child_count()
		child.get_child(randi_range(0, count)).show()

func rotateSun() -> void:
	$"Sun Container/Rays1".rotation = sunRot
	$"Sun Container/Rays2".rotation = -sunRot + 45
	var numerator = CYCLE_TIME - timer.time_left
	sunRot = (numerator/CYCLE_TIME) * (180/PI)

func moveFish(node: Node) -> void:
	allFishVelocity.y = allFishVelocity.y + GRAVITY
	
	node.global_position.y += allFishVelocity.y
	node.global_position.x = -fishRotVelocity * 50
	
	if node.global_position.y > 0:
		node.global_position.y = 0

func fishJump() -> void:
	showRandomFish(fish_container)
	allFishVelocity.y = ALL_FISH_INITIAL_VELOCITY

const FLIP_WINDOW: float = 0.3  # how much of the jump the flip spans, either side of the peak
var fishDisplayRot := 0.0

func wiggleFish(node: Node) -> void:
	fishRotVelocity += -sign(fishRot) * wiggleAcceleration
	fishRot += fishRotVelocity
	
	# 0 at launch, 1 at the peak, 2 at landing
	var jumpProgress: float = (allFishVelocity.y - ALL_FISH_INITIAL_VELOCITY) / -ALL_FISH_INITIAL_VELOCITY
	# 0 before the window, ramps to 1 across it, stays 1 after
	var t: float = clampf((jumpProgress - (1.0 - FLIP_WINDOW)) / (2.0 * FLIP_WINDOW), 0.0, 1.0)
	var flipRot: float = PI * -smoothstep(0.0, 1.0, t)
	
	fishDisplayRot = fishRot + flipRot
	for child in node.get_children(false):
		child.rotation = fishDisplayRot

func _player_won(id: int) -> void:
	if !NetworkHandler.is_server: return
	print("Player ", id, " has won")
	losing_players.erase(id)
	winning_players.append(id)
	
	if winning_players.size() <= 0: _end_minigame()
