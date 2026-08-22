class_name SnakeSpecies
extends Resource

@export var id: String = "ball_python"
@export var display_name: String = "Ball Python"
@export var dorsal: Color = Color(0.42, 0.28, 0.14)
@export var ventral: Color = Color(0.78, 0.68, 0.48)
@export var pattern: Color = Color(0.12, 0.08, 0.04)
@export var pattern_type: int = 0
@export var pattern_scale: float = 14.0
@export var scale_scale: float = 36.0
@export var speed: float = 3.4
@export var burst_speed: float = 5.6
@export var turn_rate: float = 2.4
@export var radius: float = 0.075
@export var start_length: float = 3.8
@export var undulation_amp: float = 0.045
@export var undulation_freq: float = 7.5
@export var wetness: float = 0.28
@export var sss: float = 0.22

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"dorsal": dorsal,
		"ventral": ventral,
		"pattern": pattern,
		"pattern_type": pattern_type,
		"pattern_scale": pattern_scale,
		"scale_scale": scale_scale,
		"speed": speed,
		"burst_speed": burst_speed,
		"turn_rate": turn_rate,
		"radius": radius,
		"start_length": start_length,
		"undulation_amp": undulation_amp,
		"undulation_freq": undulation_freq,
		"wetness": wetness,
		"sss": sss,
	}
