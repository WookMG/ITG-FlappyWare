extends MultiplayerBase

signal finished(id)

@onready var recover_timer: Timer = $"../Recover"

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

func set_alpha() -> void:
	# Transparancy for players not authority over bird
	if !is_multiplayer_authority(): modulate = Color.hex(0xffffff80)

func _start_minigame() -> void:
	idle = false
	show_body()

@rpc("any_peer", "call_local", "unreliable")
func finish():
	if !racing: finished.emit(int(name))
	racing = false

@rpc("any_peer", "call_local", "unreliable")
func hit():
	recover_timer.start()
	recovering = true

func _on_recover_timeout() -> void:
	recovering = false
