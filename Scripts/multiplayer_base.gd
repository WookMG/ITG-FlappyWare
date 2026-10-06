class_name MultiplayerBase
extends CharacterBody2D

@onready var body_sync: MultiplayerSynchronizer = $BodySync
@onready var head_sync: MultiplayerSynchronizer = $Head/HeadSync

@onready var head: Sprite2D = $Head
@onready var username: RichTextLabel = $Head/NameContainer/username

const JUMP_VELOCITY: float = -1000
const HORIZONTAL_ACCELERATION: float = 10
const HORIZONTAL_DECCELERATION: float = -25
const MAX_HORIZONTAL_SPEED: float = 500
const WALL_ABSORBTION: float = 2.5
const PLAYERSCALE: float = 0.5

var slot: int
var player_name: String
var lastVelocity: Vector2
var isFacingLeft: bool = false
var idle: bool = true
var minigame_ended: bool = false 

func _ready() -> void:
	set_physics_process(is_multiplayer_authority())
	set_worm_properties()
	hide_body()

func show_body() -> void:
	head.show_body()
	
func hide_body() -> void:
	head.hide_body()

func jump() -> void:
	velocity.y = JUMP_VELOCITY
	$Flap.play()

func speed_to_rotation(speed) -> float:
	var rot = deg_to_rad(speed/22)
	if rot > 1.50:
			rot = 1.50
	return rot if !isFacingLeft else rot * -1

func move() -> void:
	# move horizontally and account for direction
	if !isFacingLeft:
		velocity.x += HORIZONTAL_ACCELERATION
	else:
		velocity.x -= HORIZONTAL_ACCELERATION
	
	#set horizontal max speed if over max speed
	if abs(velocity.x) >= MAX_HORIZONTAL_SPEED:
		velocity.x = MAX_HORIZONTAL_SPEED * sign(velocity.x)

func deccelerate() -> void:
	if sign(velocity.x) == 1:
		velocity.x += HORIZONTAL_DECCELERATION
	elif sign(velocity.x) == -1:
		velocity.x += -HORIZONTAL_DECCELERATION
	
	if abs(velocity.x) <= abs(HORIZONTAL_DECCELERATION):
		velocity.x = 0

func set_worm_properties() -> void:
	scale = Vector2.ONE * PLAYERSCALE

	username.text = player_name
	head.slot = slot
	head.apply_model()
	
	if isFacingLeft:
		head.flip_h = true
	set_worm_pitch()
	set_worm_location()

func set_worm_pitch() -> void:
	var sound = $Flap
	sound.pitch_scale = 0.50 + (0.25 * slot)

func set_worm_location() -> void:
	var spawns = get_parent().get_parent().get_node("Spawns")
	var spawn_pos = spawns.get_node_or_null(str(slot))

	if spawn_pos == null:
		push_error("No spawn point for slot %d" % slot)
		return
	global_position = spawn_pos.global_position
