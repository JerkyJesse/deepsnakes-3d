extends Node

enum Mode { OFFLINE, HOST, CLIENT }

var mode: Mode = Mode.OFFLINE
var species_id: String = "ball_python"
var biome_id: String = "forest"
var join_ip: String = "127.0.0.1"
var join_port: int = 7777
var spawn_index: int = 0
var local_paused: bool = false

func reset_session() -> void:
	mode = Mode.OFFLINE
	spawn_index = 0
	local_paused = false
