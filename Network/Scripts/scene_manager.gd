extends Node

const MINIGAME_END: PackedScene = preload("res://Minigames/MinigameScenes/minigame_end.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func lobby() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby/lobby.tscn")

func copyright() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func start_minigame(path: String) -> void:
	if !ResourceLoader.exists(path):
		push_error("switch_minigame: no scene at " + path)
		return
	#peer.refuse_new_connections = true
	sync_minigame.rpc(path)

func start_next_minigame() -> void:
	#TODO add this
	start_minigame("res://Scenes/Lobby/lobby.tscn") 

# This function will show who won that round etc.
@rpc("authority", "call_local", "reliable")
func end_minigame(players: Array, player_win_info: Dictionary) -> void:
	var reconstructed_players: Array[MultiplayerBird] = []
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
