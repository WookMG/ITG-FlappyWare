extends Node2D

signal pick_model(slot)

@onready var players: Node2D = $Players
var playerScene = preload("res://Minigames/MinigameScenes/knockout_player.tscn")

func _ready() -> void:
	setPlayerBodys()

func setPlayerBodys() -> void:
	for child in players.get_children():
		child = playerScene

func setSprite(slot: int) -> void:
	pick_model.emit(slot)
