extends CharacterBody2D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	$Camera2D.enabled = is_multiplayer_authority()   # if you use a camera

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	# read input and move here
