class_name MultiplayerBird
extends CharacterBody2D

@onready var body_sync: MultiplayerSynchronizer = $BodySync
@onready var head_sync: MultiplayerSynchronizer = $Head/HeadSync
@onready var gun_sync: MultiplayerSynchronizer = $Head/GunContainer/GunSync

@onready var head: Sprite2D = $Head
@onready var username: RichTextLabel = $Head/NameContainer/username

const JUMP_VELOCITY = -1000
const HORIZONTAL_ACCELERATION: float = 10
const HORIZONTAL_DECCELERATION: float = -25
const MAX_HORIZONTAL_SPEED: float = 500
const WALL_ABSORBTION: float = 2.5
const PLAYERSCALE: float = 0.5

enum Gamemode {
	LOBBY,
	FLAPPYBIRD,
	GUNGAME,
}

var game_mode: Gamemode = Gamemode.LOBBY
var lastVelocity: Vector2
var isFacingLeft = false
var slot: int
var player_name: String
#-------- LOBBY VARS --------#
var idle = true
#-------- GUNGAME VARS --------#

signal died(id: int)

@onready var bullet_scene: PackedScene = preload("res://Minigames/MinigameScenes/bullet.tscn")
@onready var bullet_spawner: MultiplayerSpawner = $Head/GunContainer/BulletSpawner
@onready var gun_container: Node2D = $Head/GunContainer
@onready var gun_anim: AnimationPlayer = $Head/GunContainer/Gun/GunAnimator

@onready var reload_sound: AudioStreamPlayer = $Head/GunContainer/Reload
@onready var shoot_1_sound: AudioStreamPlayer = $Head/GunContainer/Shoot1
@onready var shoot_2_sound: AudioStreamPlayer = $Head/GunContainer/Shoot2

@export var reload_time: float = 1.0


var is_alive: bool = true
var can_fire: bool = true
var reload: float = 0
var current_gun_anim: String = "shoot"

func _ready() -> void:
	set_physics_process(is_multiplayer_authority())
	bullet_spawner.spawn_function = _spawn_bullet
	
	match game_mode:
		Gamemode.LOBBY:
			set_collision_layer_value(2, false)
		Gamemode.GUNGAME:
			gun_container.show()
			set_collision_layer_value(2, true)
			set_collision_layer_value(3, true)
	set_bird_properties()

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

					if is_on_wall(): bounce()
					if is_on_ceiling() and velocity.y < 0: velocity.y = -velocity.y
					elif jump_input: jump()
			Gamemode.GUNGAME:
				if idle: return
				if !is_on_floor():
						velocity += get_gravity() * delta
						move()
				else:
					velocity.y = 0
					deccelerate()
				
				if is_alive:
					if !can_fire:
						if reload <= 0:
							reload_sound.play()
							can_fire = true
						else:
							reload -= delta
							can_fire = false
					if is_on_wall(): bounce()
					if is_on_ceiling() and velocity.y < 0: velocity.y = -velocity.y
					elif jump_input: jump()
					if action_input: shoot()
		lastVelocity = velocity
		head.rotation = speed_to_rotation(velocity.y)
		move_and_slide()

func jump():
	velocity.y = JUMP_VELOCITY
	$Flap.play()

func speed_to_rotation(speed):
	var rot = deg_to_rad(speed/22)
	if rot > 1.50:
			rot = 1.50
	return rot if !isFacingLeft else rot * -1

func set_bird_properties() -> void:
	scale = Vector2.ONE * PLAYERSCALE

	username.text = player_name
	head.slot = slot
	head.apply_model()
	
	if isFacingLeft:
		gun_container.get_node("Gun").scale.x *= -1
		head.flip_h = true
	set_bird_pitch()
	set_bird_location()

func set_bird_pitch() -> void:
	var sound = $Flap
	sound.pitch_scale = 0.50 + (0.25 * slot)

func set_bird_location() -> void:
	var spawns = get_parent().get_parent().get_node("Spawns")
	var spawn_pos = spawns.get_node_or_null(str(slot))

	if spawn_pos == null:
		push_error("No spawn point for slot %d" % slot)
		return
	global_position = spawn_pos.global_position

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

func bounce() -> void:
	gun_container.get_node("Gun").scale.x *= -1
	if !isFacingLeft and lastVelocity.x > 0:
		isFacingLeft = true
		head.flip_h = isFacingLeft
		current_gun_anim = "inverted_shoot"
		velocity.x =- lastVelocity.x / WALL_ABSORBTION
	elif isFacingLeft and lastVelocity.x < 0:
		isFacingLeft = false
		head.flip_h = isFacingLeft
		current_gun_anim = "shoot"
		velocity.x =- lastVelocity.x / WALL_ABSORBTION

@rpc("any_peer", "call_local", "reliable")
func hit_pipe() -> void:
	idle = true
	set_collision_layer_value(2, false)
	set_bird_properties()
	head.rotation = 0
	velocity = Vector2.ZERO

#-------- GUNGAME FUNCTIONS --------#

func _start_gun_minigame() -> void:
	idle = false

func shoot() -> void:
	if can_fire:
		can_fire = false
		reload = reload_time
		gun_anim.play(current_gun_anim)
		
		var new_pitch = randf_range(0.5, 2.0)
		if randf() > 0.5:
			shoot_1_sound.pitch_scale = new_pitch
			shoot_1_sound.play()
		else:
			shoot_2_sound.pitch_scale = new_pitch
			shoot_2_sound.play()
		bullet_spawner.spawn()

func _spawn_bullet(_data = null) -> Node:
	var bullet : RigidBody2D = bullet_scene.instantiate()
	
	var bullet_spawn = gun_container.get_node("Gun").get_node("BulletSpawn")
	bullet.global_position = bullet_spawn.global_position
	bullet.rotation = bullet_spawn.global_rotation
	bullet.direction = bullet_spawn.global_transform.x.normalized()
	
	return bullet

@rpc("any_peer", "call_local", "reliable")
func die():
	if is_alive: died.emit(int(name))
	is_alive = false
	head.alive = false
	head.apply_model()
	
	set_collision_layer_value(3, false) #This layer is what bullets scan for
	#TODO Blood splatter particles
