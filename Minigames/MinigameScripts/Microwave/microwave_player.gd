extends MultiplayerBase

@onready var input_component: InputComponent = %InputComponent
@onready var jump_component: JumpComponent = %JumpComponent

signal breakOut(id: int)
signal hit

var defaultJumpVelocity: float
var jumpVelocity: float = -250

var integrity: int = 1 #set in mincrowave_minigame.gd
var won: bool = false

func _ready() -> void:
	super._ready()
	defaultJumpVelocity = jump_component.jumpVelocity
	jump_component.jumpVelocity = jumpVelocity
	show_body()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	var sender_id := multiplayer.get_remote_sender_id()
	
	if integrity == 0:
		broke_out.rpc()
		won = true
		jump_component.jumpVelocity = defaultJumpVelocity
		integrity = -1
	
	
	if input_component.jumpPressed:
		if !won:
			integrity -= 1
			hit.emit()
	
	if is_on_ceiling() && velocity.y < 0:
		velocity.y = -velocity.y
	
	head.rotation = speed_to_rotation(velocity.y)
	
	move_and_slide()

@rpc("any_peer", "call_local", "unreliable")
func broke_out():
	breakOut.emit(int(name))

func _start_minigame() -> void:
	pass
