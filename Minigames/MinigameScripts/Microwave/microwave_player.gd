extends MultiplayerBase

var jumps: int = 0


func _ready() -> void:
	super._ready()
	show_body()



func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if Input.is_action_just_pressed("Jump"):
		jump()
		jumps += 1
	
	#if jumps >



func _start_minigame() -> void:
	pass
