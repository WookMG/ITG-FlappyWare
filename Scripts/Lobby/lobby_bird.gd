class_name LobbyBird
extends CharacterBody2D

const JUMP_VELOCITY = -1000
const HORIZONTAL_ACCELERATION: float = 20
const HORIZONTAL_DECCELERATION: float = -25
const MAX_HORIZONTAL_SPEED: float = 1500
const WALL_ABSORBTION: float = 2.5
const UI_FADE: float = 1.0

var isOnFloor = false
var isFacingLeft = false
var lastVelocity: Vector2


#Multiplayer Shizzy
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	Global.start_game.connect(on_start_game)
	Global.end_game.connect(on_end_game)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return #Multiplayer Shizzy
	
	match Global.current_state:
		Global.States.Idle:
			if Input.is_action_just_pressed("Jump") || Input.is_action_just_pressed("Alternate Action"):
				jump()
				Global.start_game.emit()
			position.y += 5*sin(Time.get_ticks_msec()/100.0)
			show_ui_to_self()
		Global.States.Playing:
			fade_controlls_ui_for_self(delta)
			
			if !is_on_floor():
				velocity += get_gravity() * delta
			else:
				velocity.y = 0
			
			if is_on_wall():
				if !isFacingLeft && lastVelocity.x > 0:
					isFacingLeft = true
					$Sprite2D.flip_h = isFacingLeft
					velocity.x = - lastVelocity.x / WALL_ABSORBTION
				elif isFacingLeft && lastVelocity.x < 0:
					isFacingLeft = false
					$Sprite2D.flip_h = isFacingLeft
					velocity.x = - lastVelocity.x / WALL_ABSORBTION
			
			if is_on_ceiling() && velocity.y < 0:
				velocity.y = -velocity.y
			
			# Handle jump.
			if Input.is_action_just_pressed("Jump"):
				jump()
			
			# Handle movement.
			if Input.is_action_pressed("Alternate Action"):
				move()
			else:
				deccelerate()
			
			$Sprite2D.rotation = speed_to_rotation(velocity.y)
			
			lastVelocity = velocity
			move_and_slide()
		
		Global.States.Dead:
			position.x -= Global.bird_speed

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
	return rot

func on_start_game():
	pass

func on_end_game():
	$LightSmack.play()

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

# Client side functions
func show_ui_to_self() -> void:
	show_controlls.rpc_id(name.to_int()) 

func fade_controlls_ui_for_self(delta: float) -> void:
	fade_controlls_ui.rpc_id(name.to_int(), delta)
