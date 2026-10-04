class_name PlayerInfo
extends RefCounted

var peer_id: int
var player_name: String
var is_host: bool = false
var is_ready: bool = false
var ping_ms: int = 0
var slot: int 

func _init(id: int, name: String, host: bool = false) -> void:
	peer_id = id
	player_name = name
	is_host = host

func set_player_name(name: String):
	player_name = name

func set_slot() -> void:
	var i = 1
	for id in NetworkHandler.connected_players:
		if peer_id == int(id):
			slot = i
		i += 1
