extends MultiplayerBase

signal died(id: int)

@onready var bullet_scene: PackedScene = preload("uid://bkqy6qikx2hky")
@onready var bullet_spawner: MultiplayerSpawner = $Head/GunContainer/BulletSpawner
@onready var gun_container: Node2D = $Head/GunContainer
@onready var gun_anim: AnimationPlayer = $Head/GunContainer/Gun/GunAnimator

@onready var reload_sound: AudioStreamPlayer = $Head/GunContainer/Reload
@onready var shoot_sound: AudioStreamPlayer = $Head/GunContainer/Shoot

@export var reload_time: float = 1.0

var is_alive: bool = true
var can_fire: bool = true
var reload: float = 0
var current_gun_anim: String = "shoot"

func _ready() -> void:
	super._ready()
	bullet_spawner.spawn_function = _spawn_bullet
	gun_container.show()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if minigame_ended: return
	var jump_input = Input.is_action_just_pressed("Jump")
	var action_input = Input.is_action_just_pressed("Alternate Action")
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

func set_worm_properties() -> void:
	if isFacingLeft:
		gun_container.get_node("Gun").scale.x *= -1
	super.set_worm_properties()

func _start_minigame() -> void:
	idle = false
	show_body()

func shoot() -> void:
	if can_fire:
		can_fire = false
		reload = reload_time
		gun_anim.play(current_gun_anim)
		
		shoot_sound.pitch_scale = randf_range(0.5, 2.0)
		shoot_sound.play()
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
