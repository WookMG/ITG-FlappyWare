extends MultiplayerBase

signal breakOut(id: int)

var jumps: int = 0
var goal: int = 20

var won: bool = false

func _ready() -> void:
	super._ready()
	show_body()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if Input.is_action_just_pressed("Jump"):
		jump()
		jumps += 1
	
	if jumps >= goal && !won:
		breakOut.emit(int(name))
		won = true



func _start_minigame() -> void:
	pass
