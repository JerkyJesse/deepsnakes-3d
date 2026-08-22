extends Node

const PATH := "user://save.cfg"

var high_score: int = 0

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		high_score = int(cfg.get_value("score", "high", 0))

func submit(score: int) -> void:
	if score > high_score:
		high_score = score
		var cfg := ConfigFile.new()
		cfg.set_value("score", "high", high_score)
		cfg.save(PATH)
