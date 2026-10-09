extends Control

@onready var textAnimations: AnimationPlayer = $Title/AnimationPlayer

@onready var main_panel: Panel = $MainPanel
@onready var input_text_panel: Panel = $InputTextPanel
@onready var ip: LineEdit = $InputTextPanel/VBoxContainer/IP
@onready var ip_text: RichTextLabel = $InputTextPanel/VBoxContainer/IPText
@onready var username: LineEdit = $InputTextPanel/VBoxContainer/Username
@onready var username_text: RichTextLabel = $InputTextPanel/VBoxContainer/UsernameText

@onready var bark_fart: AudioStreamPlayer = $BarkFart
@onready var snap: AudioStreamPlayer = $Snap

var ip_open: bool = false
var username_open: bool = false
var inputPanelOpen: bool = false
var place: String = "Menu"

func _ready() -> void:
	bark_fart.play()
	var aniList = textAnimations.get_animation_list()
	textAnimations.current_animation = aniList[randi_range(0, aniList.size() - 1)]
	if textAnimations.current_animation == "huh?":
		$VideoStreamPlayer/Timer.start()
		await get_tree().create_timer(2.15).timeout
		$"Splash Art/Eye Container".show()


func _on_host_pressed() -> void:
	snap.play()
	toggleMainPanel()
	toggle_username_input()
	var username_submitted: String = await username.text_submitted
	toggle_username_input()
	var error = NetworkHandler.start_server(username_submitted)
	if error == OK:
		SceneManager.lobby()

func _on_join_pressed() -> void:
	snap.play()
	toggleMainPanel()
	toggle_ip_input()
	var ip_submitted: String = await ip.text_submitted
	snap.play()
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
	snap.play()
	SceneManager.copyright()

func _on_settings_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	snap.play()
	await snap.finished
	get_tree().quit()

func toggle_ip_input():
	place = "IP"
	
	ip_open = !ip_open
	input_text_panel.visible = ip_open
	ip.visible = ip_open
	ip_text.visible = ip_open
	
	if ip_open: ip.grab_focus()

func toggle_username_input():
	place = "Username"
	
	username_open = !username_open
	input_text_panel.visible = username_open
	username.visible = username_open
	username_text.visible = username_open
	
	if username_open: username.grab_focus()

func _on_timer_timeout() -> void:
	$VideoStreamPlayer.play()
	$VideoStreamPlayer/Timer.wait_time = 10
	$VideoStreamPlayer/Timer.start()

func toggleMainPanel() -> void:
	if main_panel.visible:
		main_panel.hide()
	else:
		main_panel.show()

func _on_return_pressed() -> void:
	snap.play()
	match place:
		"Username":
			toggle_username_input()
		"IP":
			toggle_ip_input()
		"Menu":
			return
	toggleMainPanel()
