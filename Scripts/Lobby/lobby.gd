class_name Lobby
extends Node2D

var main = preload("res://Scenes/main.tscn")
var fishingMinigame = preload("res://Minigames/MinigameScenes/fishing_minigame.tscn")

@onready var multiplayer_spawner: HighLevelMultiplayerSpawner = $MultiplayerSpawner
@onready var pipe_container: Node2D = $"Pipe Container"

const PLAYERSCALE: float = 0.5
var defaultPlayerY: float
var playerNodes: Array[LobbyBird] # HighLevelNetworkHandler.connectedPlayerIDs are the connected player IDs

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(peer_disconnected)
	
	playerNodes.resize(4)
	defaultPlayerY = get_viewport().get_visible_rect().size.y / 2

func _on_slot_0_child_entered_tree(node: Node) -> void:
	_onPlayerJoined(node, 0)

func _on_slot_1_child_entered_tree(node: Node) -> void:
	_onPlayerJoined(node, 1)

func _on_slot_2_child_entered_tree(node: Node) -> void:
	_onPlayerJoined(node, 2)

func _on_slot_3_child_entered_tree(node: Node) -> void:
	_onPlayerJoined(node, 3)

func _onPlayerJoined(node: Node, slot: int) -> void:
	if !multiplayer.is_server():
		return
	while slot == -1:
		await HighLevelNetworkHandler.playerIDsUpdated
		if not is_instance_valid(node):
			return  # bird was freed while waiting
	
	playerNodes[slot] = node
	setBirdProperties(node, slot)

func setBirdProperties(node: LobbyBird, slot: int) -> void:
	assert(slot >= 0 && slot <= 3, "slot \"" + str(slot) + "\"out of bounds (0,3)")
	node.scale = node.scale * PLAYERSCALE
	setBirdLocation(node, slot)
	setBirdPitch(node, slot)
	#print("properties set")

func setBirdPitch(node: LobbyBird, slot: int) -> void:
	var sound = node.find_child("Flap")
	if slot == 0:
		sound.pitch_scale = 1
	elif slot == 1:
		sound.pitch_scale = 1.5
	elif slot == 2:
		sound.pitch_scale = 0.5
	elif slot == 3:
		sound.pitch_scale = 0.7


func setBirdLocation(node: LobbyBird, slot: int):
	var divisionLength: float = get_viewport().get_visible_rect().size.x / 4
	slot += 1
	node.global_position.y = defaultPlayerY
	node.global_position.x = (slot * divisionLength) - divisionLength/2

#Return Pipe
func _onReturnPipeEntered(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is LobbyBird:
		var id := body.name.to_int()
		#if id == multiplayer.get_unique_id():
			#return  # the host never leaves the lobby
		send_player_to_menu.call_deferred(id)

#Start Pipe
func _onStartPipeEntered(body: Node2D) -> void:
	var i = randi_range(0,0) #change range when more games added
	if !multiplayer.is_server():
		return
	if body is LobbyBird:
		print("WORKING ON THIS")

func send_player_to_menu(client_id: int) -> void:
	pass

	var player := get_node_or_null(str(client_id))
	if player:
		player.queue_free()
		await player.tree_exited
	load_scene.rpc_id(client_id)
	await get_tree().create_timer(0.3).timeout
	if multiplayer.get_peers().has(client_id):
		multiplayer.multiplayer_peer.disconnect_peer(client_id, true)

@rpc("authority", "call_remote", "reliable")
func load_scene() -> void:
	HighLevelNetworkHandler.peer.close()
	multiplayer.multiplayer_peer = null  # only ever runs on clients now
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

# disconnect player if they clsoe their window
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()

func on_server_disconnected() -> void:
	print("server_disconnected")
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file.call_deferred("res://Scenes/main.tscn")

func peer_disconnected(peer_id: int) -> void:
	var bird := get_node_or_null(str(peer_id))
	if bird == null:
		return
	var idx := playerNodes.find(bird)
	if idx != -1:
		playerNodes[idx] = null
	bird.queue_free()
	
func _on_bird_collide(body: Node2D) -> void:
	if body is LobbyBird:
		body.hit_pipe()
		setBirdLocation(body, int(body.get_parent().name))

func getPlayerNodes() -> Array:
	return playerNodes
