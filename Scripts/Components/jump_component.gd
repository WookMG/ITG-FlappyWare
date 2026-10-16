class_name JumpComponent extends Node

@export var jumpVelocity: float = -1000
@export var character_body_2D: CharacterBody2D
@export var input_component: InputComponent

func _ready() -> void:
	assert(input_component, "Jump Component was never assigned an Input Component")
	assert(character_body_2D, "Jump Component was never assigned a Character Body 2D")

func _physics_process(delta: float) -> void:
	if input_component.jumpPressed:
		jump()
		input_component.jumpPressed = false

func jump() -> void:
	character_body_2D.velocity.y = jumpVelocity
