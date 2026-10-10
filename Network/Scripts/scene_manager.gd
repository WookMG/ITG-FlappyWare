extends Node

const MINIGAME_END: PackedScene = preload("res://Minigames/MinigameScenes/minigame_end.tscn")
const LOBBY: String = "uid://ba0rv2ceiwgwd"
const FLAPPYWORM: String = "uid://dvaeefi471jp8"

@export var defaultCapacity: int = 2
var playlist: Array[String]
var guaranteedGames: Array[String]
var enabledKeys: Array[String]
#Games go here
var games: Dictionary = {
"Gun Minigame": {"path": "res://Minigames/MinigameScenes/GunGame/gun_minigame.tscn", "weight": 2, "enabled": true},
"Fishing Minigame": {"path": "res://Minigames/MinigameScenes/Fishing/fishing_minigame.tscn", "weight": 1, "enabled": true}
}

func lobby() -> void:
	get_tree().change_scene_to_file(LOBBY)

func copyright() -> void:
	get_tree().change_scene_to_file(FLAPPYWORM)

func start_minigame(path: String) -> void:
	if !NetworkHandler.is_server: return
	if !ResourceLoader.exists(path):
		push_error("switch_minigame: no scene at " + path)
		return
	#peer.refuse_new_connections = true
	sync_minigame.rpc(path)

func start_next_minigame() -> void:
	if playlist.is_empty():
		start_minigame(LOBBY)
	else:
		start_minigame(playlist.pop_front()) 

# Only call if there is at least 1 Minigame enabled
func setPlaylist() -> void:
	playlist.clear()
	enabledKeys.clear()
	var enabledWeights: Array[int]
	
	for i in games.keys():
		if games.get(i)["enabled"]:
			enabledKeys.append(games.find_key(games.get(i)))
			enabledWeights.append(games.get(i)["weight"])
	
	for i in guaranteedGames.size():
		playlist.append(games.get(guaranteedGames[i])["path"])
	
	while playlist.size() < defaultCapacity:
		var rng = RandomNumberGenerator.new()
		var game = games[enabledKeys[rng.rand_weighted(enabledWeights)]]["path"]
		playlist.append(game)

func getState(game: String) -> bool:
	return games[game]["enabled"]

func changeState(game: String) -> bool:
	games[game]["enabled"] = !games[game]["enabled"]
	return games[game]["enabled"]

# This function will show who won that round etc.
@rpc("authority", "call_local", "reliable")
func end_minigame(players: Array, player_win_info: Dictionary) -> void:
	var reconstructed_players: Array[MultiplayerBase] = []
	for path in players:
		var player_node = get_node_or_null(path)
		if player_node: reconstructed_players.append(player_node)
		else: push_error("Could not find player node at path: ", path)
	
	var minigame_end_scene = MINIGAME_END.instantiate()
	minigame_end_scene.players = reconstructed_players
	minigame_end_scene.win_info = player_win_info
	get_tree().current_scene.add_child(minigame_end_scene)

@rpc("authority", "call_local", "reliable")
func sync_minigame(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)
