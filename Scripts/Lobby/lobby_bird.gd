class_name LobbyBird
extends CharacterBody2D

const JUMP_VELOCITY = -1000
const HORIZONTAL_ACCELERATION: float = 20
const HORIZONTAL_DECCELERATION: float = -25
const MAX_HORIZONTAL_SPEED: float = 1500

var isOnFloor = false
var isFacingLeft = false

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
			position.y += 5*sin(Time.get_ticks_msec()/100)
				
		Global.States.Playing:
			if not is_on_floor():
				velocity += get_gravity() * delta
				
			# Handle jump.
			if Input.is_action_just_pressed("Jump"):
				jump()
				
			# Handle movement.
			if global_position.x >= get_viewport_rect().size.x && !isFacingLeft:
				velocity.x = -velocity.x
				isFacingLeft = true
				scale.x = -scale.x
			elif global_position.x <= 0 && isFacingLeft:
				velocity.x = -velocity.x
				scale.x = -scale.x
				isFacingLeft = false
			
			if Input.is_action_pressed("Alternate Action"):
				move()
			else:
				deccelerate()
			
			$Sprite2D.rotation = speed_to_rotation(velocity.y)
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
	
	if abs(velocity.x) <= 0:
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
