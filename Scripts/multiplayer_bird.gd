class_name MultiplayerBird
extends CharacterBody2D

const JUMP_VELOCITY = -1000.0

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
			if Input.is_action_just_pressed("Jump"):
				jump()
				Global.start_game.emit()
			position.y += 5*sin(Time.get_ticks_msec()/100)
				
		Global.States.Playing:
			if not is_on_floor():
				velocity += get_gravity() * delta
				
			# Handle jump.
			if Input.is_action_just_pressed("Jump"):
				jump()
				
			$Sprite2D.rotation = speed_to_rotation(velocity.y)
			move_and_slide()
		Global.States.Dead:
			position.x -= Global.bird_speed


func jump():
	velocity.y = JUMP_VELOCITY
	$Flap.play()

func speed_to_rotation(speed):
	var rot = deg_to_rad(speed/22)
	if rot > 1.50:
			rot = 1.50
	return rot

func on_start_game():
	pass

func on_end_game():
	$LightSmack.play()
