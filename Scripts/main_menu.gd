extends Control

@onready var textAnimations: AnimationPlayer = $Title/AnimationPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var aniList = textAnimations.get_animation_list()
	textAnimations.current_animation = aniList[randi_range(0, aniList.size() - 1)]
	if textAnimations.current_animation == "huh?":
		$"Splash Art/Eye Container".show()

func _on_host_pressed() -> void:
	var error = NetworkHandler.start_server()
	if error == OK:
		SceneManager.lobby()

func _on_join_pressed() -> void:
	# address pop up
	var address = null
	if address:
		NetworkHandler.start_client(address)
	else:
		NetworkHandler.start_client()
	SceneManager.lobby()
	
func _on_play_pressed() -> void:
	SceneManager.copyright()

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
