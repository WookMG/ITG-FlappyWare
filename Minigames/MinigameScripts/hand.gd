extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D

func play():
	sprite.play("open")
	await sprite.animation_finished
