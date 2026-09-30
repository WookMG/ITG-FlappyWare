class_name LobbyBird
extends CharacterBody2D

const JUMP_VELOCITY = -1000
const HORIZONTAL_ACCELERATION: float = 10
const HORIZONTAL_DECCELERATION: float = -25
const MAX_HORIZONTAL_SPEED: float = 500
const WALL_ABSORBTION: float = 2.5
const UI_FADE: float = 1.0

var isOnFloor = false
var isFacingLeft = false
var lastVelocity: Vector2
var idle = true
var faded = false

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return #Multiplayer Shizzy
	
	if idle:
		show_ui_to_self()
		if Input.is_action_just_pressed("Jump"):
			jump()
			position.y += 5*sin(Time.get_ticks_msec()/100.0)
			idle = false
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
			
		if Input.is_action_just_pressed("Jump"):
			jump()
		
		$Sprite2D.rotation = speed_to_rotation(velocity.y)
		
		if !faded:
			fade_controlls_ui_for_self(delta)
		
		lastVelocity = velocity
		move_and_slide()

func jump():
	velocity.y = JUMP_VELOCITY
	$Flap.play()

func move() -> void:
	#move horizontally and account for direction
	if !isFacingLeft:
		velocity.x += HORIZONTAL_ACCELERATION
	else:
		velocity.x += -HORIZONTAL_ACCELERATION
	
	#set horizontal max speed if over max speed
	if abs(velocity.x) >= MAX_HORIZONTAL_SPEED:
		velocity.x = MAX_HORIZONTAL_SPEED * sign(velocity.x)

func bouce() -> void:
	if !isFacingLeft && lastVelocity.x > 0:
		isFacingLeft = true
		$Sprite2D.flip_h = isFacingLeft
		velocity.x = - lastVelocity.x / WALL_ABSORBTION
	elif isFacingLeft && lastVelocity.x < 0:
		isFacingLeft = false
		$Sprite2D.flip_h = isFacingLeft
		velocity.x = - lastVelocity.x / WALL_ABSORBTION

func deccelerate() -> void:
	if sign(velocity.x) == 1:
		velocity.x += HORIZONTAL_DECCELERATION
	elif sign(velocity.x) == -1:
		velocity.x += -HORIZONTAL_DECCELERATION
	
	if abs(velocity.x) <= abs(HORIZONTAL_DECCELERATION):
		velocity.x = 0

func speed_to_rotation(speed):
	var rot = deg_to_rad(speed/22)
	if rot > 1.50:
			rot = 1.50
	print(rot)
	return rot if !isFacingLeft else rot * -1

#Multiplayer Shizzy
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

# Server side functions
@rpc("authority", "call_local", "reliable")
func show_controlls() -> void:
	$"Controlls Display".show()

@rpc("authority", "call_local", "reliable")
func fade_controlls_ui(delta: float) -> void:
	if $"Controlls Display/RichTextLabel".modulate.a > 0:
		$"Controlls Display/RichTextLabel".modulate.a -= UI_FADE * delta
		if $"Controlls Display/RichTextLabel".modulate.a < 0:
			$"Controlls Display/RichTextLabel".modulate.a = 0
			faded = true

# Client side functions
func show_ui_to_self() -> void:
	show_controlls.rpc_id(name.to_int()) 

func fade_controlls_ui_for_self(delta: float) -> void:
	fade_controlls_ui.rpc_id(name.to_int(), delta)
