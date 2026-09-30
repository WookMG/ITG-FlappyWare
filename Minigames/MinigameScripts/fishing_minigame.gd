# fishing_minigame.gd
extends MinigameBase

@onready var sun: Node2D = $"Sun Container"
@onready var fish_container: Node2D = $"Fish Container"

var sunRot: float = 0
const CYCLE_TIME: float = 80
var timer = Timer.new()

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
	if !multiplayer.is_server():
		return
	#Sun
	sun.global_position = $"Sun Container/Start Position".global_position
	timer.wait_time = CYCLE_TIME
	timer.one_shot = false
	sun.add_child(timer)
	timer.start()
	
	#Fish
	showRandomFish(fish_container)
	setFishPositions(fish_container)
	fishJump() #move to when we want fish to jump
	maxWiggleAngle = maxWiggleAngle * (PI/180)
	minWiggleAngle = -maxWiggleAngle
	fishRot = maxWiggleAngle


func _physics_process(delta: float) -> void:
	rotateSun($"Sun Container/Rays1")
	moveFish(fish_container)
	wiggleFish(fish_container)


func _p1FishTouched(body: Node2D) -> void:
	pass # Replace with function body.


func _p2FishTouched(body: Node2D) -> void:
	pass # Replace with function body.


func _p3FishTouched(body: Node2D) -> void:
	pass # Replace with function body.


func _p4FishTouched(body: Node2D) -> void:
	pass # Replace with function body.

func showRandomFish(node: Node) -> void:
	for child in node.get_children(false):
		var spriteCount = child.find_child("Sprites Container").get_child_count()
		#hide current sprites
		for j in child.find_child("Sprites Container").get_child_count():
			child.find_child("Sprites Container").get_child(j).hide()
		#show new sprite
		var randint = randi_range(0, spriteCount - 1)
		child.find_child("Sprites Container").get_child(randint).show()

func setFishPositions(node: Node) -> void:
	for child in node.get_children(false):
		child.global_position = node.find_child("Start Position").global_position
		child.find_child("Start Position").queue_free()

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
		fishJump()

func fishJump() -> void:
	showRandomFish(fish_container)
	allFishVelocity.y = ALL_FISH_INITIAL_VELOCITY

const FLIP_WINDOW: float = 2  # how much of the jump the flip spans, either side of the peak

func wiggleFish(node: Node) -> void:
	fishRotVelocity += -sign(fishRot) * wiggleAcceleration
	fishRot += fishRotVelocity

	# 0 at launch, 1 at the peak, 2 at landing
	var jumpProgress: float = (allFishVelocity.y - ALL_FISH_INITIAL_VELOCITY) / -ALL_FISH_INITIAL_VELOCITY

	# 0 before the window, ramps to 1 across it, stays 1 after
	var t: float = clampf((jumpProgress - (1.0 - FLIP_WINDOW)) / (2.0 * FLIP_WINDOW), 0.0, 1.0)
	var flipRot: float = PI * -smoothstep(0.0, 1.0, t)

	for child in node.get_children(false):
		child.rotation = fishRot + flipRot
