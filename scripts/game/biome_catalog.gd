class_name BiomeCatalog
extends RefCounted

static func all() -> Array:
	return [_forest(), _desert(), _swamp(), _canyon()]

static func get_biome(id: String) -> Dictionary:
	for b in all():
		if b.id == id:
			return b
	return _forest()

static func _forest() -> Dictionary:
	return {
		"id": "forest",
		"display_name": "Forest Floor",
		"sun_color": Color(1.0, 0.95, 0.82),
		"sun_energy": 1.15,
		"sun_rotation": Vector3(-48, -35, 0),
		"ambient": Color(0.18, 0.22, 0.16),
		"fog_color": Color(0.35, 0.42, 0.3),
		"fog_density": 0.012,
		"ground_a": Color(0.18, 0.14, 0.08),
		"ground_b": Color(0.28, 0.32, 0.14),
		"grass_color": Color(0.22, 0.38, 0.12),
		"sky_top": Color(0.28, 0.42, 0.55),
		"sky_horizon": Color(0.62, 0.7, 0.55),
		"has_water": false,
		"has_grass": true,
		"rock_color": Color(0.32, 0.28, 0.22),
	}

static func _desert() -> Dictionary:
	return {
		"id": "desert",
		"display_name": "Desert Wash",
		"sun_color": Color(1.0, 0.92, 0.7),
		"sun_energy": 1.55,
		"sun_rotation": Vector3(-62, -20, 0),
		"ambient": Color(0.32, 0.26, 0.18),
		"fog_color": Color(0.78, 0.68, 0.48),
		"fog_density": 0.008,
		"ground_a": Color(0.62, 0.48, 0.28),
		"ground_b": Color(0.78, 0.62, 0.38),
		"grass_color": Color(0.45, 0.42, 0.22),
		"sky_top": Color(0.35, 0.55, 0.78),
		"sky_horizon": Color(0.95, 0.82, 0.55),
		"has_water": false,
		"has_grass": false,
		"rock_color": Color(0.55, 0.4, 0.28),
	}

static func _swamp() -> Dictionary:
	return {
		"id": "swamp",
		"display_name": "Blackwater Swamp",
		"sun_color": Color(0.85, 0.9, 0.7),
		"sun_energy": 0.7,
		"sun_rotation": Vector3(-28, 40, 0),
		"ambient": Color(0.1, 0.14, 0.1),
		"fog_color": Color(0.22, 0.3, 0.2),
		"fog_density": 0.028,
		"ground_a": Color(0.12, 0.14, 0.08),
		"ground_b": Color(0.2, 0.22, 0.1),
		"grass_color": Color(0.16, 0.28, 0.12),
		"sky_top": Color(0.22, 0.28, 0.24),
		"sky_horizon": Color(0.4, 0.45, 0.32),
		"has_water": true,
		"has_grass": true,
		"rock_color": Color(0.2, 0.22, 0.16),
	}

static func _canyon() -> Dictionary:
	return {
		"id": "canyon",
		"display_name": "Red Canyon",
		"sun_color": Color(1.0, 0.85, 0.65),
		"sun_energy": 1.35,
		"sun_rotation": Vector3(-40, 70, 0),
		"ambient": Color(0.22, 0.14, 0.1),
		"fog_color": Color(0.55, 0.35, 0.25),
		"fog_density": 0.01,
		"ground_a": Color(0.45, 0.22, 0.12),
		"ground_b": Color(0.62, 0.32, 0.16),
		"grass_color": Color(0.32, 0.28, 0.12),
		"sky_top": Color(0.25, 0.4, 0.7),
		"sky_horizon": Color(0.9, 0.55, 0.35),
		"has_water": false,
		"has_grass": false,
		"rock_color": Color(0.55, 0.25, 0.14),
	}
