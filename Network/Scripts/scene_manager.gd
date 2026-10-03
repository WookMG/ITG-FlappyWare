extends Node

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

func end_minigame() -> void:
	pass
	
@rpc("authority", "call_local", "reliable")
func sync_minigame(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)
