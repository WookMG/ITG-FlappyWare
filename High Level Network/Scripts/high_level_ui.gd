extends Control

func _on_server_pressed() -> void:
	HighLevelNetworkHandler.start_server()
	hide()

func _on_client_pressed() -> void:
	HighLevelNetworkHandler.start_client()
	hide()
