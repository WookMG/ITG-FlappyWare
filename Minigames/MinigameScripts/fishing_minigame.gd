# fishing_minigame.gd
extends MinigameBase

@onready var sun: Node2D = $"Sun Container"
@onready var fish_container: Node2D = $"Fish Container"
var fishActive := false

var sunRot: float = 0
const CYCLE_TIME: float = 80
var timer = Timer.new()

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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	body.inWater = true
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	body.inWater = false
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _ready() -> void:
	super._ready()
	
	sun.global_position = $"Sun Container/Start Position".global_position
	timer.wait_time = CYCLE_TIME
	timer.one_shot = false
	sun.add_child(timer)
	timer.start()
	
	setFishPositions(fish_container)
	maxWiggleAngle = maxWiggleAngle * (PI/180)
	minWiggleAngle = -maxWiggleAngle
	fishRot = maxWiggleAngle

func _on_all_players_loaded() -> void:  # server only, from MinigameBase
	_refresh_fish_visibility()
	fishActive = true
	timeBeforeFish.wait_time = randf_range(minWait, maxWait)
	timeBeforeFish.start()

func _refresh_fish_visibility() -> void:  # server only
	var flags := PackedByteArray()
	var kids := fish_container.get_children(false)
	for slot in kids.size():
		var id := HighLevelNetworkHandler.connectedPlayerIDs[slot]
		var present: bool = id != HighLevelNetworkHandler.EMPTY_SLOT \
				and multiplayer.get_peers().has(id.to_int())
		flags.append(1 if present else 0)
	apply_fish_visibility(flags)           # server
	sync_fish_visibility.rpc(flags)        # clients

@rpc("authority", "call_remote", "reliable")
func sync_fish_visibility(flags: PackedByteArray) -> void:
	apply_fish_visibility(flags)

func apply_fish_visibility(flags: PackedByteArray) -> void:
	var kids := fish_container.get_children(false)
	for i in mini(kids.size(), flags.size()):
		kids[i].visible = flags[i] == 1

func _physics_process(_delta: float) -> void:
	rotateSun($"Sun Container/Rays1")
	if !multiplayer.is_server() or !fishActive:
		return
	moveFish(fish_container)
	wiggleFish(fish_container)
	sync_fish_state.rpc(fish_container.global_position, fishDisplayRot)

func _catchTimerExpire() -> void:
	fishJump()
	#gameSwitchTime.start()
	pass

func _gameSwitchTimerExpire() -> void:
	# HighLevelNetworkHandler.switch_minigame() <- put random minigame here
	pass

func _p1FishTouched(body: Node2D) -> void:
	
	pass # Replace with function body.


func _p2FishTouched(body: Node2D) -> void:
	pass # Replace with function body.


func _p3FishTouched(body: Node2D) -> void:
	pass # Replace with function body.


func _p4FishTouched(body: Node2D) -> void:
	pass # Replace with function body.

# --- sprites: server picks, everyone applies ---
func showRandomFish(node: Node) -> void:  # server only
	var indices := PackedInt32Array()
	for child in node.get_children(false):
		var count: int = child.find_child("Sprites Container").get_child_count()
		indices.append(randi_range(0, count - 1))
	apply_fish_sprites(indices)
	sync_fish_sprites.rpc(indices)


func apply_fish_sprites(indices: PackedInt32Array) -> void:
	var kids := fish_container.get_children(false)
	for i in kids.size():
		var sprites := kids[i].find_child("Sprites Container")
		for s in sprites.get_children():
			s.hide()
		sprites.get_child(indices[i]).show()

@rpc("authority", "call_remote", "reliable")
func sync_fish_sprites(indices: PackedInt32Array) -> void:
	apply_fish_sprites(indices)

# --- movement: server simulates, clients copy ---
@rpc("authority", "call_remote", "unreliable")
func sync_fish_state(pos: Vector2, rot: float) -> void:
	fish_container.global_position = pos
	for child in fish_container.get_children(false):
		child.rotation = rot

func setFishPositions(node: Node) -> void:
	for child in node.get_children(false):
		var marker := child.find_child("Start Position")
		if marker:
			child.global_position = marker.global_position
			marker.queue_free()

func rotateSun(node: Node) -> void:
	node.rotation = sunRot
	node.rotation = -sunRot + 45
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
