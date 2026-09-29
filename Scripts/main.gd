extends Node2D

@onready var disconnect_dialog: AcceptDialog = $DisconnectDialog

func _ready() -> void:
	#Tells the player the reason they disconnected
	if HighLevelNetworkHandler.disconnect_reason != "":
		disconnect_dialog.title = "Disconnected"
		disconnect_dialog.dialog_text = HighLevelNetworkHandler.disconnect_reason
		disconnect_dialog.popup_centered()
		HighLevelNetworkHandler.disconnect_reason = ""  # show it only once
