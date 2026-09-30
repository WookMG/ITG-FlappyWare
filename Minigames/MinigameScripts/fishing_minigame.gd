extends Node2D

const PLAYERSCALE: float = 0.5

@export var player_scene: PackedScene
@export var spawn_points: Array[Vector2]
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var spawn_points_container: Node2D = $"Start Positions"

func _ready() -> void:
	spawn_points.resize(4)
	for i in mini(spawn_points_container.get_child_count(), 4):
		spawn_points[i] = spawn_points_container.get_child(i).global_position

	spawner.spawn_function = _spawn_player
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_spawn_when_ready()
	else:
		HighLevelNetworkHandler.client_loaded.rpc_id(1)

func _spawn_when_ready() -> void:
	var waited := 0.0
	while waited < 10.0:
		var all_loaded := true
		for id in multiplayer.get_peers():
			if !HighLevelNetworkHandler.loaded_peers.has(id):
				all_loaded = false
				break
		if all_loaded:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	for slot in HighLevelNetworkHandler.connectedPlayerIDs.size():
		var id := HighLevelNetworkHandler.connectedPlayerIDs[slot]
		if id != HighLevelNetworkHandler.EMPTY_SLOT and multiplayer.get_peers().has(id.to_int()):
			spawner.spawn({"id": id.to_int(), "slot": slot})

const PLAYER_SCENE := preload("res://Minigames/MinigameScenes/fishing_bird.tscn")

func _spawn_player(data: Dictionary) -> Node:
	var p := PLAYER_SCENE.instantiate()
	p.name = str(data.id)
	p.position = spawn_points[data.slot]
	return p

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	
	body.inWater = true
	body.velocity.y = body.velocity.y * body.AERODYNAMICS

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is not FishingBird or !body.is_multiplayer_authority():
		return
	
	body.inWater = false
	body.velocity.y = body.velocity.y * body.AERODYNAMICS


func setBirdProperties(node: LobbyBird, slot: int) -> void:
	assert(slot >= 0 && slot <= 3, "slot \"" + str(slot) + "\"out of bounds (0,3)")
	node.scale = node.scale * PLAYERSCALE
	setBirdColor(node, slot)
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
	

func setBirdColor(node: LobbyBird, slot: int) -> void:
	var sprite: Sprite2D = node.find_child("Sprite2D")
	if slot == 0:
		sprite.modulate = Global.p1Color
	elif slot == 1:
		sprite.modulate = Global.p2Color
	elif slot == 2:
		sprite.modulate = Global.p3Color
	elif slot == 3:
		sprite.modulate = Global.p4Color

func _on_peer_disconnected(peer_id: int) -> void:
	var container := spawner.get_node(spawner.spawn_path)
	var player := container.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
