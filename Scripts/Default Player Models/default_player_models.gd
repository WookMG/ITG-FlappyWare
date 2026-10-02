class_name DefaultPlayerModels
extends Sprite2D

var slot: int

const worm = preload("res://Assets/Sprites/Worm/head.png")
const mf_with_1_million_toes = preload("res://Assets/Sprites/Caterpillar/head.png")
const snail = preload("res://Assets/Sprites/Snail/head.png")
const maggot = preload("res://Assets/Sprites/Maggot/head.png")

func _ready() -> void:
	$Worm.hide() #hide default model

func _pick_model_received(slot: int) -> void:
	if slot == 0:
		$Worm.show()
		texture = worm
	elif slot == 1:
		$Caterpillar.show()
		texture = mf_with_1_million_toes
	elif slot == 2:
		$Snail.show()
		texture = snail
	elif slot == 3:
		$Maggot.show()
		texture = maggot
