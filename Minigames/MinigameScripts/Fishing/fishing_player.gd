extends MultiplayerBase

signal won(id: int)

const BUOYANCY: float = 90
const AERODYNAMICS: float = 0.6

var isOnFloor: bool = false
var inWater: bool = false

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	velocity += get_gravity() * delta
	
	if is_on_ceiling() && velocity.y < 0:
		velocity.y = -velocity.y
	
	if Input.is_action_just_pressed("Jump"):
		jump()
	
	if inWater:
		velocity.y -= BUOYANCY
	
	head.rotation = speed_to_rotation(velocity.y)
	move_and_slide()

@rpc("any_peer", "call_local", "unreliable")
func win() -> void: # called by fish
	won.emit(int(name))
	#TODO disable controlls and make it apparent that they've won

@rpc("any_peer", "call_local", "unreliable")
func enteredWater() -> void:
	inWater = true
	velocity.y = velocity.y * AERODYNAMICS

@rpc("any_peer", "call_local", "unreliable")
func exitedWater() -> void:
	inWater = false
	velocity.y = velocity.y * AERODYNAMICS

func _start_minigame() -> void:
	pass
