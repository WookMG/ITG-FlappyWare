extends MultiplayerBase

signal breakOut(id: int)
signal hit

var jumpVelocity: float = -250

var integrity: int = 1 #set in mincrowave_minigame.gd
var won: bool = false

func _ready() -> void:
	super._ready()
	jump_velocity = jumpVelocity
	show_body()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if integrity == 0:
		broke_out.rpc()
		won = true
		jump_velocity = -1000
		integrity = -1
	
	if !is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("Jump"):
		jump()
		if !won:
			integrity -= 1
			hit.emit()
	
	if is_on_ceiling() && velocity.y < 0:
		velocity.y = -velocity.y
	
	head.rotation = speed_to_rotation(velocity.y)
	
	lastVelocity = velocity
	move_and_slide()

@rpc("any_peer", "call_local", "unreliable")
func broke_out():
	breakOut.emit(int(name))

func _start_minigame() -> void:
	pass
