extends Node2D

@onready var sprites_container: Node2D = $"Sprites Container"
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var allFishVelocity: Vector2
const ALL_FISH_INITIAL_VELOCITY: float = -6
const FLIP_WINDOW: float = 0.3  # how much of the jump the flip spans, either side of the peak

@export var gravity: float = 0.1
@export var fishMoveSpeed: float = 1
@export var maxWiggleAngle: float = 45
var fishRot: float = 0 
var fishRotVelocity: float = 0
var minWiggleAngle: float = 0
var wiggleAcceleration: float = 0.007
var fishDisplayRot := 0.0
var jumped: bool = false

func _ready() -> void:
	for child in sprites_container.get_children():
		child.hide()
	
	sprites_container.get_child(randi_range(0, sprites_container.get_child_count() - 1)).show()
	
	maxWiggleAngle = maxWiggleAngle * (PI/180)
	minWiggleAngle = -maxWiggleAngle
	fishRot = maxWiggleAngle

func _physics_process(delta: float) -> void:
	wiggleFish()
	moveFish()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is MultiplayerBase:
		body.win.rpc()
		print("called body.won.rpc()")
		self.queue_free()

func wiggleFish() -> void:
	fishRotVelocity += -sign(fishRot) * wiggleAcceleration
	fishRot += fishRotVelocity
	
	# 0 at launch, 1 at the peak, 2 at landing
	var jumpProgress: float = (allFishVelocity.y - ALL_FISH_INITIAL_VELOCITY) / -ALL_FISH_INITIAL_VELOCITY
	# 0 before the window, ramps to 1 across it, stays 1 after
	var t: float = clampf((jumpProgress - (1.0 - FLIP_WINDOW)) / (2.0 * FLIP_WINDOW), 0.0, 1.0)
	var flipRot: float = PI * -smoothstep(0.0, 1.0, t)
	
	fishDisplayRot = fishRot + flipRot
	
	rotation = fishDisplayRot

func _fishJump() -> void:
	allFishVelocity.y = ALL_FISH_INITIAL_VELOCITY
	jumped = true

func moveFish() -> void:
	if jumped:
		allFishVelocity.y = allFishVelocity.y + gravity
		
		global_position.y += allFishVelocity.y * fishMoveSpeed
