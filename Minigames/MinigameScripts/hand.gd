extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var spotlight: AudioStreamPlayer = $spotlight

func play(player: MultiplayerBase):
	sprite.play("open")
	await sprite.animation_finished
	light.show()
	spotlight.play()
	player.show()

func fade_in():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.hex(0xffffffff), 1.5)
