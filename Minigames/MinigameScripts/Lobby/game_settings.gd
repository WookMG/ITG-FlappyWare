extends Control

#TODO create menu that allows for adding guaranteed games

#-----------------------------------------------------------------#
# When adding a new game button to the menu, please name it 
# after what it's named as in the games disctionary in Scene Manager.
#-----------------------------------------------------------------#

# Game Buttons
@onready var gun_minigame: TextureButton = $"Game Settings Panel/Games/ScrollContainer/VBoxContainer/HSplitContainer/Left Column/Gun Minigame"
@onready var fishing_minigame: TextureButton = $"Game Settings Panel/Games/ScrollContainer/VBoxContainer/HSplitContainer/Right Column/Fishing Minigame"

@onready var player_settings_panel: Panel = $"Player Settings Panel"
@onready var game_settings_panel: Panel = $"Game Settings Panel"
@onready var game_settings_cog: Button = $"Game Settings Cog"
@onready var player_settings_cog: Button = $"Player Settings Cog"
@onready var error: RichTextLabel = $"Game Settings Panel/Error"

@onready var snap: AudioStreamPlayer = $Snap
@onready var snap_high: AudioStreamPlayer = $"Snap High"
@onready var bark_fart: AudioStreamPlayer = $BarkFart

var inMenu: bool = false
var guaranteeToggle: bool = false
var disabled: float = 0.5
var enabled: float = 1

var green: Color = Color(0.4, 1.0, 0.37, 1.0)
var defaultColor: Color = Color(1.0, 1.0, 1.0, 1.0)

var errorTimer: Timer

func _ready() -> void:
	player_settings_panel.hide()
	game_settings_panel.hide()
	#if NetworkHandler.is_server: game_settings_cog.show()
	#else: game_settings_cog.hide()
	var keys = SceneManager.games.keys()
	for i in keys:
		var button = self.find_child(i)
		if SceneManager.games.get(i).get("enabled"): button.modulate.a = enabled
		else: button.modulate.a = disabled
	errorTimer = Timer.new()
	self.add_child(errorTimer)

func _physics_process(delta: float) -> void:
	if error.modulate.a > 0:
		error.modulate.a -= 0.01
		error.position.y -= 0.2

func _on_player_settings_cog_pressed() -> void:
	if inMenu: return
	snap_high.play()
	inMenu = true
	player_settings_panel.show()

func _on_game_settings_cog_pressed() -> void:
	if inMenu: return
	snap_high.play()
	inMenu = true
	game_settings_panel.show()

func _on_back_to_game_pressed() -> void:
	snap.play()
	player_settings_panel.hide()
	game_settings_panel.hide()
	inMenu = false

func _on_gun_minigame_pressed() -> void:
	gameSelectLogic("Gun Minigame", gun_minigame)

func _on_fishing_minigame_pressed() -> void:
	gameSelectLogic("Fishing Minigame", fishing_minigame)

func _on_check_box_toggled(toggled_on: bool) -> void:
	guaranteeToggle = !guaranteeToggle

func gameSelectLogic(game: String, button: TextureButton) -> void:
	var state: bool = SceneManager.getState(game)
	if guaranteeToggle:
		if SceneManager.guaranteedGames.find(game) == -1:
			SceneManager.guaranteedGames.append(game)
			button.modulate = green
			button.find_child("Queued").show()
		elif SceneManager.guaranteedGames.find(game) != -1:
			SceneManager.guaranteedGames.erase(game)
			button.modulate = defaultColor
			button.find_child("Queued").hide()
		
		if state: button.modulate.a = enabled
		else: button.modulate.a = disabled
		snap.play()
		SceneManager.setPlaylist()
		return
	
	state = SceneManager.changeState(game)
	var isAnyGameEnabled = false
	var keys = SceneManager.games.keys()
	for i in keys:
		if SceneManager.games.get(i).get("enabled"):
			isAnyGameEnabled = true
			break
	if !isAnyGameEnabled: 
		SceneManager.changeState(game)
		bark_fart.play()
		showError()
		return
	
	snap.play()
	if state: 
		button.modulate.a = enabled
		button.find_child("Removed").hide()
	else: 
		button.modulate.a = disabled
		button.find_child("Removed").show()
	
	SceneManager.setPlaylist()

func showError() -> void:
	errorTimer.wait_time = 2
	error.modulate.a = 1
	error.position.y = 154.0
	error.show()
