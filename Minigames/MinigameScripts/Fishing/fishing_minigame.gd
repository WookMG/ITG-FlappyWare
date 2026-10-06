extends MinigameBase

@onready var sun: Node2D = $"Sun Container"
@onready var fish_container: Node2D = $"Fish Container"

var sunRot: float = 0
const CYCLE_TIME: float = 80
var timer: Timer

@onready var timeBeforeFish: Timer = $"Time Before Fish"
@export var minWait: float = 1
@export var maxWait: float = 5
@onready var gameSwitchTime: Timer = $"Time Limit/Game Switch Time"

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

func _on_area_2d_body_entered(body: Node2D) -> void:
	body.inWater = true #TODO make inWater in the player script rather than here and use an rpc()
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	body.inWater = false
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _ready() -> void:
	super._ready()
	
	timer = Timer.new()
	timer.wait_time = CYCLE_TIME
	timer.one_shot = false
	sun.add_child(timer)
	timer.start()
	
	#setFishPositions(playerNodes)
	maxWiggleAngle = maxWiggleAngle * (PI/180)
	minWiggleAngle = -maxWiggleAngle
	fishRot = maxWiggleAngle

func _on_all_players_loaded() -> void:  # server only, from MinigameBase
	timeBeforeFish.wait_time = randf_range(minWait, maxWait)
	timeBeforeFish.start()
	super._on_all_players_loaded()

func _physics_process(_delta: float) -> void:
	rotateSun()
	if !multiplayer.is_server():
		return
	moveFish(fish_container)
	wiggleFish(fish_container)

func _catchTimerExpire() -> void:
	fishJump()
	#gameSwitchTime.start()
	pass

func _gameSwitchTimerExpire() -> void:
	# HighLevelNetworkHandler.switch_minigame() <- put random minigame here
	pass

func showRandomFish(node: Node) -> void:  # server only
	for child in node.get_children(false):
		var count: int = child.find_child("Sprites Container").get_child_count()
		child.get_child(randi_range(0, count)).show()

#func setFishPositions(node: Node) -> void:
	#for i in fish_container.size():
		#var marker := fish_container.find_child("Start Position")
		#if marker:
			#child.global_position = marker.global_position
			#marker.queue_free()

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
