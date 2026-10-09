extends Control

@export var defaultCapacity: int = 3

#Games go here
var games: Dictionary = {
"gunMinigame": {"path": "res://Minigames/MinigameScenes/GunGame/gun_minigame.tscn", "weight": 2},
"fishingMinigame": {"path": "res://Minigames/MinigameScenes/Fishing/fishing_minigame.tscn", "weight": 1}
}

@onready var player_settings_panel: Panel = $"Player Settings Panel"
@onready var game_settings_panel: Panel = $"Game Settings Panel"
@onready var game_settings_cog: Button = $"Game Settings Cog"
@onready var player_settings_cog: Button = $"Player Settings Cog"

@onready var snap: AudioStreamPlayer = $Snap
@onready var snap_high: AudioStreamPlayer = $"Snap High"

var inMenu = false

func _ready() -> void:
	player_settings_panel.hide()
	game_settings_panel.hide()
	if NetworkHandler.is_server: game_settings_cog.show()
	else: game_settings_cog.hide()

func _on_player_settings_cog_pressed() -> void:
	if inMenu: return
	snap_high.play()
	inMenu = true
	player_settings_panel.show()


func _on_game_settings_cog_pressed() -> void:
	if inMenu: return
	snap_high.play()
	inMenu = true
	game_settings_panel.show()

func setDefaultPlaylist() -> void:
	var keys = games.keys()
	var weights: Array[int]
	for i in keys:
			weights.append(games.get(i).get("weight"))
	
	while SceneManager.playlist.size() < defaultCapacity:
		var rng = RandomNumberGenerator.new()
		var randomWeightedLevelPath = games.get(keys[rng.rand_weighted(weights)]).get("path")
		SceneManager.playlist.append(randomWeightedLevelPath)


func _on_back_to_game_pressed() -> void:
	snap.play()
	player_settings_panel.hide()
	game_settings_panel.hide()
	inMenu = false
