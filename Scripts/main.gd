extends Node2D

@onready var disconnect_dialog: AcceptDialog = $DisconnectDialog

func _ready() -> void:
	#Tells the player the reason they disconnected
	if NetworkHandler.disconnect_reason != "":
		disconnect_dialog.title = "Disconnected"
		disconnect_dialog.dialog_text = NetworkHandler.disconnect_reason
		disconnect_dialog.popup_centered()
		NetworkHandler.disconnect_reason = ""  # show it only once
