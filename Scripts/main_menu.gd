extends Control



func _on_quit_pressed() -> void:
	get_tree().quit()



func _on_host_pressed() -> void:
	HighLevelNetworkHandler.start_server()



func _on_join_pressed() -> void:
	HighLevelNetworkHandler.start_client()
