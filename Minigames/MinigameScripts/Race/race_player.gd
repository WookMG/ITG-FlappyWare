extends MultiplayerBase

signal finished(id)

@onready var recover_timer: Timer = $"../Recover"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var racing: bool = true
var recovering: bool = false

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if minigame_ended or idle: return
	
	var jump_input = Input.is_action_just_pressed("Jump")
	var action_input = Input.is_action_just_pressed("Alternate Action")
	if !is_on_floor():
		velocity += get_gravity() * delta
		move()
	else:
		velocity.y = 0
		deccelerate()
	if is_on_ceiling() and velocity.y < 0: velocity.y = -velocity.y
	elif jump_input and racing: jump()
	
	lastVelocity = velocity
	head.rotation = speed_to_rotation(velocity.y)
	move_and_slide()

func _start_minigame() -> void:
	if !is_multiplayer_authority(): modulate = Color.hex(0xffffff50)
	idle = false
	show_body()

@rpc("any_peer", "call_local", "unreliable")
func finish():
	if racing: finished.emit(int(name))
	racing = false

@rpc("any_peer", "call_local", "unreliable")
func hit():
	recover_timer.start()
	animation_player.play("hit")
	recovering = true
	set_collision_layer_value(3, false) #This layer is what pipes scan for
	
	if velocity.x >= 50: velocity.x = 50
	horizontal_acceleration = 5
	max_horizontal_speed = 300

func _on_recover_timeout() -> void:
	recovering = false
	animation_player.play("RESET")
	set_collision_layer_value(3, true)
	
	horizontal_acceleration = 10.0
	max_horizontal_speed = 500
