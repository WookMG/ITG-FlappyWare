class_name MultiplayerBird
extends CharacterBody2D

@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

const JUMP_VELOCITY = -1000
const HORIZONTAL_ACCELERATION: float = 10
const HORIZONTAL_DECCELERATION: float = -25
const MAX_HORIZONTAL_SPEED: float = 500
const WALL_ABSORBTION: float = 2.5
const PLAYERSCALE: float = 0.5

enum Gamemode {
	LOBBY,
	FLAPPYBIRD,
	
}

var game_mode: Gamemode = Gamemode.LOBBY
var lastVelocity: Vector2
var slot: int
#-------- LOBBY VARS --------#
var isFacingLeft = false
var idle = true

func _ready() -> void:
	set_physics_process(is_multiplayer_authority())

func _physics_process(delta: float) -> void:
	var jump_input = Input.is_action_just_pressed("Jump")
	var action_input = Input.is_action_just_pressed("Alternate Action")
	if is_multiplayer_authority():
		# GIANT IF STATEMENT WALL YAYAYAYAY
		match game_mode:
			Gamemode.LOBBY:
				if idle:
					position.y += 0.5 * sin(Time.get_ticks_msec()/500.0)
					if jump_input:
						jump()
						idle = false
						set_collision_layer_value(2, true)
				else:
					if !is_on_floor():
						velocity += get_gravity() * delta
						move()
					else:
						velocity.y = 0
						deccelerate()
					if is_on_wall():
						bouce()
					if is_on_ceiling() && velocity.y < 0:
						velocity.y = -velocity.y
					elif jump_input:
						jump()
					lastVelocity = velocity
					$Model/Head.rotation = speed_to_rotation(velocity.y)
		move_and_slide()

func jump():
	velocity.y = JUMP_VELOCITY
	$Flap.play()

func speed_to_rotation(speed):
	var rot = deg_to_rad(speed/22)
	if rot > 1.50:
			rot = 1.50
	return rot if !isFacingLeft else rot * -1

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))

@rpc("any_peer", "call_local", "reliable")
func set_bird_properties(slot: int) -> void:
	self.slot = slot
	
	scale = Vector2.ONE * PLAYERSCALE
	set_bird_pitch(slot)
	set_bird_location(slot)

func set_bird_pitch(slot: int) -> void:
	var sound = $Flap
	sound.pitch_scale = 0.50 + (0.25 * slot)

func set_bird_location(slot: int) -> void:
	var spawns = get_parent().get_node("Spawns")
	var spawn_pos = spawns.get_node_or_null(str(slot))

	if spawn_pos == null:
		push_error("No spawn point for slot %d" % slot)
		return
	global_position = spawn_pos.global_position

#-------- LOBBY FUNCTIONS --------#
func move() -> void:
	# move horizontally and account for direction
	if !isFacingLeft:
		velocity.x += HORIZONTAL_ACCELERATION
	else:
		velocity.x += -HORIZONTAL_ACCELERATION
	
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

func bouce() -> void:
	if !isFacingLeft && lastVelocity.x > 0:
		isFacingLeft = true
		$Model/Head.flip_h = isFacingLeft
		velocity.x = - lastVelocity.x / WALL_ABSORBTION
	elif isFacingLeft && lastVelocity.x < 0:
		isFacingLeft = false
		$Model/Head.flip_h = isFacingLeft
		velocity.x = - lastVelocity.x / WALL_ABSORBTION

@rpc("any_peer", "call_local", "reliable")
func hit_pipe() -> void:
	idle = true
	set_collision_layer_value(2, false)
	$Model/Head.rotation = 0
	velocity = Vector2.ZERO
