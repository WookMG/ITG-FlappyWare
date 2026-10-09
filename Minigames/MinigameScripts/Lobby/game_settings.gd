extends Control

@export var defaultCapacity: int = 1

#Games go here
var games: Dictionary = {
"gunMinigame": {"path": "res://Minigames/MinigameScenes/GunGame/gun_minigame.tscn", "weight": 2},
"fishingMinigame": {"path": "res://Minigames/MinigameScenes/Fishing/fishing_minigame.tscn", "weight": 1}
}

#func _ready() -> void:
	#if !NetworkHandler.is_server: return
	#setDefaultPlaylist()
	#print("host")

func setDefaultPlaylist() -> void:
	var keys = games.keys()
	var weights: Array[int]
	for i in keys:
			weights.append(games.get(i).get("weight"))
	
	while SceneManager.playlist.size() < defaultCapacity:
		var rng = RandomNumberGenerator.new()
		var randomWeightedLevelPath = games.get(keys[rng.rand_weighted(weights)]).get("path")
		SceneManager.playlist.append(randomWeightedLevelPath)
