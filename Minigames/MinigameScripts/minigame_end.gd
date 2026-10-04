extends Node2D

@onready var hand_1: Node2D = $HandContainer/Hand1
@onready var hand_2: Node2D = $HandContainer/Hand2
@onready var hand_3: Node2D = $HandContainer/Hand3
@onready var hand_4: Node2D = $HandContainer/Hand4
@onready var l1: Marker2D = $"LoserContainer/1"
@onready var l2: Marker2D = $"LoserContainer/2"
@onready var l3: Marker2D = $"LoserContainer/3"
@onready var l4: Marker2D = $"LoserContainer/4"
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var loser_light: PointLight2D = $LoserContainer/PointLight2D

@onready var start: AudioStreamPlayer = $start
@onready var loop: AudioStreamPlayer = $loop
@onready var end: AudioStreamPlayer = $end

var players: Array[MultiplayerBird]
var win_info: Dictionary

var hands: Array[Node2D] = []
var hands_used: Array[Node2D] = []
var ls: Array[Marker2D] = []

var players_won: Array[MultiplayerBird] = []

func _ready() -> void:
	hands = [hand_1, hand_2, hand_3, hand_4]
	ls = [l1, l2, l3, l4]
	for player in players:
		player.game_mode = player.Gamemode.END
		player.head.rotation = 0
		player.hide()
		player.hide_body()
		
	var i = 0
	for hand in hands:
		hand.spotlight.pitch_scale = 1 + (.1 * i)
		i += 1
	
	set_players()
	await play_end()
	await get_tree().create_timer(5).timeout
	end_end()

func set_players() -> void:
	for id in win_info:
		var i = players.find_custom(func(player): return player.name == id)
		if win_info[id]:
			var hand = hands.pop_front()
			hands_used.append(hand)
			players_won.append(players[i])
			players[i].global_position = hand.global_position
		else: players[i].global_position = ls.pop_front().global_position

func play_end() -> void:
	start.finished.connect(loop_roll)
	start.play()
	
	var tween = create_tween()
	tween.tween_property(canvas_modulate, "color", Color.hex(0x888888ff), 1.5)
	hand_1.fade_in()
	hand_2.fade_in()
	hand_3.fade_in()
	hand_4.fade_in()
	await get_tree().create_timer(2.5).timeout
	for hand in hands_used:
		hand.play(players_won.pop_front())
		await get_tree().create_timer(.3).timeout
	await get_tree().create_timer(.5).timeout
	for player in players:
		player.show()
	loser_light.show()
	loop.stop()
	end.play()

func loop_roll():
	loop.play()
	
func end_end() -> void:
	#TODO Play END throw whatever
	SceneManager.start_next_minigame()
