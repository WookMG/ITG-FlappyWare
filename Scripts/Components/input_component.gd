class_name InputComponent extends Node

var jumpPressed: bool = false
var alternateActionPressed: bool = false
var swapGamemodePressed: bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		jumpPressed = true
	
	if Input.is_action_just_pressed("Alternate Action"):
		alternateActionPressed = true
	
	if Input.is_action_just_pressed("Swap Gamemode"):
		swapGamemodePressed = true
