extends Control

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

@onready var snap: AudioStreamPlayer = $Snap
@onready var snap_high: AudioStreamPlayer = $"Snap High"
@onready var bark_fart: AudioStreamPlayer = $BarkFart

var inMenu: bool = false
var disabled: float = 0.5
var enabled: float = 1

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

func gameSelectLogic(game: String, button: TextureButton) -> void:
	var state: bool = SceneManager.changeState(game)
	
	var isAnyGameEnabled = false
	var keys = SceneManager.games.keys()
	for i in keys:
		if SceneManager.games.get(i).get("enabled"):
			isAnyGameEnabled = true
	if !isAnyGameEnabled: 
		SceneManager.changeState(game)
		bark_fart.play()
		return
	else: 
		snap.play()
	
	if state: button.modulate.a = enabled
	else: button.modulate.a = disabled
	
	SceneManager.setPlaylist()
