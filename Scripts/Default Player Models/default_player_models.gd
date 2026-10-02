class_name DefaultPlayerModels
extends Node2D

var slot = -1 

func _ready() -> void:
	$Worm.hide() #hide default model
	slot = 2 #change later
	_pick_model_received(slot) #change later

func _physics_process(delta: float) -> void:
	$".".global_position.x += 3

func _pick_model_received(slot: int) -> void:
	if slot == 0:
		$Worm.show()
	elif slot == 1:
		$Caterpillar.show()
	elif slot == 2:
		$Snail.show()
	elif slot == 3:
		$Maggot.show()
