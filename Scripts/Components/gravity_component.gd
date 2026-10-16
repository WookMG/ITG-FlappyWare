class_name GravityComponent extends Node

@export var character_body_2D: CharacterBody2D

func _ready() -> void:
	assert(character_body_2D, "Gravity Component was never assigned a Character Body 2D")

func _physics_process(delta: float) -> void:
	if !character_body_2D.is_on_floor():
		character_body_2D.velocity += character_body_2D.get_gravity() * delta
