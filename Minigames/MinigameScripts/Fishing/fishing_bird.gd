class_name FishingBird
extends CharacterBody2D

const JUMP_VELOCITY = -1000
const UI_FADE: float = 1.0
const BUOYANCY: float = 90
const AERODYNAMICS: float = 0.6

var isOnFloor = false
#var idle = true
var faded = false
var inWater = false

# player.gd
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return #Multiplayer Shizzy
	
	#if idle:
		#show_ui_to_self()
		#if Input.is_action_just_pressed("Jump"):
			#jump()
			#position.y += 5*sin(Time.get_ticks_msec()/100.0)
			#idle = false
	else:
		if !is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0
		
		if is_on_ceiling() && velocity.y < 0:
			velocity.y = -velocity.y
		
		if Input.is_action_just_pressed("Jump"):
			jump()
		
		$Sprite2D.rotation = speed_to_rotation(velocity.y)
		
		if !faded:
			fade_controlls_ui_for_self(delta)
		
		if inWater:
			velocity.y -= BUOYANCY
		
		move_and_slide()

func jump():
	velocity.y = JUMP_VELOCITY
	$Flap.play()

func speed_to_rotation(speed):
	var rot = deg_to_rad(speed/22)
	if rot > 1.50:
			rot = 1.50
	return rot

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
