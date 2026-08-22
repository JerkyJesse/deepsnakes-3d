extends Node

const PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.0022
var fov: float = 85.0
var master_volume: float = 0.85

func _ready() -> void:
	load_from_disk()
	apply_volume()

func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(master_volume, 0.001, 1.0)))

func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	mouse_sensitivity = float(cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity))
	fov = float(cfg.get_value("video", "fov", fov))
	master_volume = float(cfg.get_value("audio", "master_volume", master_volume))

func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "fov", fov)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(PATH)
	apply_volume()
