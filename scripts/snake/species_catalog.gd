class_name SpeciesCatalog
extends RefCounted

const PATHS := {
	"ball_python": "res://resources/species/ball_python.tres",
	"timber_rattlesnake": "res://resources/species/timber_rattlesnake.tres",
	"cottonmouth": "res://resources/species/cottonmouth.tres",
	"sidewinder": "res://resources/species/sidewinder.tres",
}

static func all() -> Array:
	var out: Array = []
	for id in PATHS.keys():
		out.append(get_species(str(id)))
	return out

static func get_species(id: String) -> Dictionary:
	var path: String = str(PATHS.get(id, PATHS["ball_python"]))
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is SnakeSpecies:
			return (res as SnakeSpecies).to_dict()
	return _fallback(id)

static func _fallback(id: String) -> Dictionary:
	var dummy := SnakeSpecies.new()
	match id:
		"timber_rattlesnake":
			dummy.id = "timber_rattlesnake"
			dummy.display_name = "Timber Rattlesnake"
			dummy.dorsal = Color(0.55, 0.45, 0.28)
			dummy.pattern_type = 1
			dummy.speed = 4.1
			dummy.burst_speed = 6.8
			dummy.radius = 0.07
			dummy.start_length = 3.4
			dummy.undulation_amp = 0.055
			dummy.undulation_freq = 8.5
		"cottonmouth":
			dummy.id = "cottonmouth"
			dummy.display_name = "Cottonmouth"
			dummy.dorsal = Color(0.22, 0.24, 0.14)
			dummy.pattern_type = 2
			dummy.speed = 3.7
			dummy.wetness = 0.55
			dummy.radius = 0.08
		"sidewinder":
			dummy.id = "sidewinder"
			dummy.display_name = "Sidewinder"
			dummy.dorsal = Color(0.72, 0.58, 0.34)
			dummy.pattern_type = 3
			dummy.speed = 4.6
			dummy.burst_speed = 7.2
			dummy.radius = 0.055
			dummy.start_length = 2.9
			dummy.undulation_amp = 0.08
			dummy.undulation_freq = 10.0
	return dummy.to_dict()
