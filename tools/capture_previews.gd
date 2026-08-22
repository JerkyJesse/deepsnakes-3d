extends Node

const OUT_DIR := "res://docs/previews"
const SNAKE_SCENE := preload("res://scenes/snake/player_snake.tscn")
const PREY_SCENE := preload("res://scenes/game/prey.tscn")
const WORLD_SCENE := preload("res://scenes/game/world.tscn")
const MENU_SCENE := preload("res://scenes/menus/main_menu.tscn")
const BIOMES := {
	"forest": "res://scenes/biomes/forest.tscn",
	"desert": "res://scenes/biomes/desert.tscn",
	"swamp": "res://scenes/biomes/swamp.tscn",
	"canyon": "res://scenes/biomes/canyon.tscn",
}

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	Network.start_offline()
	await _run()
	get_tree().quit()

func _run() -> void:
	await _shot_menu()
	await _shot_biome("forest", "ball_python", "biome-forest", Vector3(9.0, 5.2, 16.0), Vector3(0.0, 0.4, 2.0))
	await _shot_biome("desert", "sidewinder", "biome-desert", Vector3(11.0, 6.0, 14.0), Vector3(1.0, 0.3, 1.0))
	await _shot_biome("swamp", "cottonmouth", "biome-swamp", Vector3(8.0, 3.8, 15.0), Vector3(2.0, 0.2, -2.0))
	await _shot_biome("canyon", "timber_rattlesnake", "biome-canyon", Vector3(10.0, 5.5, 13.0), Vector3(0.0, 0.4, 0.0))
	await _shot_species("ball_python", "species-ball-python")
	await _shot_species("timber_rattlesnake", "species-timber-rattlesnake")
	await _shot_species("cottonmouth", "species-cottonmouth")
	await _shot_species("sidewinder", "species-sidewinder")
	await _shot_first_person()

func _shot_menu() -> void:
	await _clear()
	add_child(MENU_SCENE.instantiate())
	await _warm(50)
	await _save("menu")

func _shot_biome(biome_id: String, species_id: String, file_name: String, cam_pos: Vector3, look: Vector3) -> void:
	await _clear()
	GameState.local_paused = false
	add_child(load(str(BIOMES[biome_id])).instantiate())
	var cam := _cine_cam(cam_pos, look, 68.0)
	_spawn_snake(species_id, Vector3(0.0, 0.12, 4.5), 0.0, false)
	_spawn_snake("cottonmouth" if species_id != "cottonmouth" else "ball_python", Vector3(7.0, 0.12, -6.0), 2.2, false)
	_spawn_prey(Vector3(0.4, 0.12, 2.2), 0)
	_spawn_prey(Vector3(-1.2, 0.12, 1.4), 2)
	await _warm(130)
	cam.current = true
	await _save(file_name)

func _shot_species(species_id: String, file_name: String) -> void:
	await _clear()
	GameState.local_paused = true
	add_child(load(BIOMES["forest"]).instantiate())
	var s := _spawn_snake(species_id, Vector3(0.0, 0.12, 2.4), 0.15, false)
	_pose_wave(s)
	var cam := _cine_cam(Vector3(1.55, 0.52, 3.55), Vector3(0.05, 0.12, 1.35), 52.0)
	cam.near = 0.02
	await _warm(80)
	await _save(file_name)
	GameState.local_paused = false

func _shot_first_person() -> void:
	await _clear()
	GameState.local_paused = false
	GameState.species_id = "timber_rattlesnake"
	GameState.biome_id = "forest"
	GameState.mode = GameState.Mode.OFFLINE
	add_child(WORLD_SCENE.instantiate())
	await _warm(150)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _save("play-first-person")

func _spawn_snake(species_id: String, origin: Vector3, yaw: float, first_person: bool) -> SnakeActor:
	var s: SnakeActor = SNAKE_SCENE.instantiate()
	s.species_id = species_id
	s.is_bot = true
	s.cinematic = first_person
	add_child(s)
	s.set_multiplayer_authority(multiplayer.get_unique_id())
	s.global_position = origin
	s.yaw = yaw
	s.configure()
	if s.camera:
		s.camera.current = first_person
	if s._head_vis:
		s._head_vis.visible = not first_person
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return s

func _pose_wave(s: SnakeActor) -> void:
	if s.body == null:
		return
	var trail := PackedVector3Array()
	var n := 46
	for i in n:
		var t := float(i) * 0.085
		trail.append(Vector3(sin(t * 2.4) * 0.32, 0.08, s.global_position.z - t))
	s.body.trail = trail
	s.global_position = trail[0]
	s.body.follow(s.global_position, s.length_m, s._sf("radius", 0.07), s._sf("undulation_amp", 0.04), s._sf("undulation_freq", 8.0), 0.016)

func _spawn_prey(origin: Vector3, kind: int) -> void:
	var p: Prey = PREY_SCENE.instantiate()
	add_child(p)
	p.setup(randi_range(100, 9999), origin, kind)

func _cine_cam(pos: Vector3, look: Vector3, fov: float) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.near = 0.04
	cam.far = 220.0
	cam.current = true
	add_child(cam)
	cam.global_position = pos
	cam.look_at(look)
	return cam

func _clear() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _warm(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame

func _save(file_name: String) -> void:
	for _i in 6:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, file_name])
	var err := img.save_png(path)
	print("preview %s -> %s (%s)" % [file_name, path, error_string(err)])
