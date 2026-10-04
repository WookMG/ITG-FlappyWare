extends Control

@onready var textAnimations: AnimationPlayer = $Title/AnimationPlayer
@onready var input_text_panel: Panel = $InputTextPanel
@onready var ip: LineEdit = $InputTextPanel/IP
@onready var ip_text: RichTextLabel = $InputTextPanel/IPText
@onready var username: LineEdit = $InputTextPanel/Username
@onready var username_text: RichTextLabel = $InputTextPanel/UsernameText

var ip_open: bool = false
var username_open: bool = false

func _ready() -> void:
	var aniList = textAnimations.get_animation_list()
	textAnimations.current_animation = aniList[randi_range(0, aniList.size() - 1)]
	if textAnimations.current_animation == "huh?":
		$VideoStreamPlayer/Timer.start()
		await get_tree().create_timer(2.15).timeout
		$"Splash Art/Eye Container".show()

func _on_host_pressed() -> void:
	toggle_username_input()
	var username_submitted: String = await username.text_submitted
	toggle_username_input()
	var error = NetworkHandler.start_server(username_submitted)
	if error == OK:
		SceneManager.lobby()

func _on_join_pressed() -> void:
	toggle_ip_input()
	var ip_submitted: String = await ip.text_submitted
	toggle_ip_input()
	toggle_username_input()
	var username_submitted: String = await username.text_submitted
	toggle_username_input()
	
	var address = ip_submitted
	if address:
		NetworkHandler.start_client(username_submitted, address)
	else:
		NetworkHandler.start_client(username_submitted)
	SceneManager.lobby()
	
func _on_play_pressed() -> void:
	SceneManager.copyright()

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()

func toggle_ip_input():
	ip_open = !ip_open
	input_text_panel.visible = ip_open
	ip.visible = ip_open
	ip_text.visible = ip_open
	
	if ip_open: ip.grab_focus()

func toggle_username_input():
	username_open = !username_open
	input_text_panel.visible = username_open
	username.visible = username_open
	username_text.visible = username_open
	
	if username_open: username.grab_focus()

func _on_timer_timeout() -> void:
	$VideoStreamPlayer.play()
	$VideoStreamPlayer/Timer.wait_time = 10
	$VideoStreamPlayer/Timer.start()
