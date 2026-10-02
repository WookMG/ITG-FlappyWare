extends Control

var lobby = preload("res://Scenes/Lobby/lobby.tscn")
var flappyBird = preload("res://Scenes/main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_host_pressed() -> void:
	get_tree().change_scene_to_packed(lobby)
	HighLevelNetworkHandler.start_server()

func _on_join_pressed() -> void:
	get_tree().change_scene_to_packed(lobby)
	HighLevelNetworkHandler.start_client()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(flappyBird)

func _on_settings_pressed() -> void:
	pass # Replace with function body.
