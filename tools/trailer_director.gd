extends Node

const DURATION := 120.0
const SNAKE_SCENE := preload("res://scenes/snake/player_snake.tscn")
const PREY_SCENE := preload("res://scenes/game/prey.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const BIOMES := {
	"forest": "res://scenes/biomes/forest.tscn",
	"desert": "res://scenes/biomes/desert.tscn",
	"swamp": "res://scenes/biomes/swamp.tscn",
	"canyon": "res://scenes/biomes/canyon.tscn",
}

var _t := 0.0
var _beat := -1
var _cam: Camera3D
var _hero: SnakeActor
var _snakes: Array[SnakeActor] = []
var _hud: Hud
var _title: Label
var _sub: Label
var _strike_cd := 0.0
var _food_id := 200

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Network.start_offline()
	GameState.local_paused = false
	_build_cards()
	_cam = Camera3D.new()
	_cam.fov = 72.0
	_cam.near = 0.03
	_cam.far = 220.0
	_cam.current = true
	add_child(_cam)
	_enter_beat(0)

func _process(delta: float) -> void:
	_t += delta
	_strike_cd -= delta
	var b := _beat_index(_t)
	if b != _beat:
		_enter_beat(b)
	_drive(delta)
	if _t >= DURATION:
		get_tree().quit()

func _beat_index(t: float) -> int:
	if t < 8.0:
		return 0
	if t < 28.0:
		return 1
	if t < 48.0:
		return 2
	if t < 68.0:
		return 3
	if t < 88.0:
		return 4
	if t < 108.0:
		return 5
	return 6

func _enter_beat(b: int) -> void:
	_beat = b
	match b:
		0:
			_setup_title()
		1:
			_setup_action("forest", "ball_python", "FOREST FLOOR", "Eat. Grow. Do not hit yourself.", false)
		2:
			_setup_action("desert", "sidewinder", "DESERT WASH", "Boost until the wash blurs.", true)
		3:
			_setup_action("swamp", "cottonmouth", "BLACKWATER SWAMP", "Strike through the fog.", false)
		4:
			_setup_canyon()
		5:
			_setup_melee()
		6:
			_setup_lineup()

func _setup_title() -> void:
	_wipe_world(false)
	var bg := ColorRect.new()
	bg.name = "TitleBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var smat := ShaderMaterial.new()
	smat.shader = load("res://shaders/menu_scales.gdshader")
	bg.material = smat
	$Cards.add_child(bg)
	$Cards.move_child(bg, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_card("DEEP SNAKES", "First person  ·  Listen server")
	_cam.current = false

func _setup_action(biome_id: String, species_id: String, title: String, sub: String, boost: bool) -> void:
	_wipe_world(true)
	_set_card(title, sub)
	add_child(load(str(BIOMES[biome_id])).instantiate())
	_hero = _spawn(species_id, Vector3(0.0, 0.12, 8.0), 0.0, true)
	_hero.forced_boost = boost
	_hero.length_m = 5.2
	_spawn(species_id, Vector3(6.0, 0.12, 2.0), 1.1, false)
	_spawn("cottonmouth", Vector3(-8.0, 0.12, -4.0), -0.6, false)
	for i in 8:
		var a := float(i) * 0.7
		_spawn_food(Vector3(sin(a) * 3.0, 0.12, 6.0 - float(i) * 2.4), i % 3)
	_cam.current = not _hero.cinematic
	if _hero.camera:
		_hero.camera.current = true
	Sfx.start_ambient()

func _setup_canyon() -> void:
	_wipe_world(true)
	_set_card("RED CANYON", "The longer snake wins.")
	add_child(load(BIOMES["canyon"]).instantiate())
	_hero = _spawn("timber_rattlesnake", Vector3(-2.0, 0.12, 6.0), 0.35, false)
	_hero.length_m = 9.5
	_hero.forced_boost = true
	var rival := _spawn("sidewinder", Vector3(1.5, 0.12, -1.0), PI + 0.2, false)
	rival.length_m = 4.2
	for i in 6:
		_spawn_food(Vector3(randf_range(-4.0, 4.0), 0.12, randf_range(-8.0, 8.0)), 2)
	_cam.current = true
	if _hero.camera:
		_hero.camera.current = false
	Sfx.start_ambient()

func _setup_melee() -> void:
	_wipe_world(true)
	_set_card("LISTEN SERVER", "Host on LAN  ·  port 7777")
	add_child(load(BIOMES["forest"]).instantiate())
	_hero = _spawn("ball_python", Vector3(0.0, 0.12, 5.0), 0.0, true)
	_hero.forced_boost = true
	_hero.length_m = 7.0
	_spawn("timber_rattlesnake", Vector3(5.0, 0.12, -3.0), 2.0, false)
	_spawn("cottonmouth", Vector3(-6.0, 0.12, -1.0), -1.2, false)
	_spawn("sidewinder", Vector3(2.0, 0.12, -8.0), 0.4, false)
	for i in 10:
		_spawn_food(Vector3(randf_range(-10.0, 10.0), 0.12, randf_range(-10.0, 10.0)), i % 3)
	_hud = HUD_SCENE.instantiate() as Hud
	add_child(_hud)
	_hud.setup_world(get_viewport().world_3d)
	if _hero.camera:
		_hero.camera.current = true
	Sfx.start_ambient()

func _setup_lineup() -> void:
	_wipe_world(true)
	GameState.local_paused = true
	_set_card("DEEP SNAKES 3D", "You are the snake.")
	add_child(load(BIOMES["forest"]).instantiate())
	var ids := ["ball_python", "timber_rattlesnake", "cottonmouth", "sidewinder"]
	for i in ids.size():
		var s := _spawn(str(ids[i]), Vector3(-4.8 + float(i) * 3.2, 0.12, 1.2), 0.35, false)
		s.length_m = 4.4
		_pose_wave(s)
	_cam.current = true
	_cam.fov = 55.0
	Sfx.start_ambient()

func _drive(delta: float) -> void:
	var local_t := _t
	match _beat:
		0:
			_cam.current = false
		1:
			_action_drive(delta)
			_maybe_hide_card(local_t, 8.0, 3.5)
		2:
			_orbit_cam(6.2, 2.4, _t * 0.55)
			_action_drive(delta)
			_maybe_hide_card(local_t, 28.0, 3.5)
		3:
			_chase_cam(3.4, 1.15)
			_action_drive(delta)
			if _hero and _hero.striking:
				_smash_zoom()
			_maybe_hide_card(local_t, 48.0, 3.5)
		4:
			_orbit_cam(7.5, 2.8, _t * 0.42)
			_action_drive(delta)
			if _t > 82.0 and _snakes.size() > 1 and not _snakes[1].is_dead:
				_snakes[1].kill("trailer")
			_maybe_hide_card(local_t, 68.0, 3.5)
		5:
			_action_drive(delta)
			if _hud and _hero:
				_hud.set_local(_hero.score, _hero.length_m, 42, "Listen server  port 7777", _hero.stamina, _hero.striking, _hero.is_swallowing())
				_hud.update_minimap(_hero.global_position, _hero.yaw)
				var board := ""
				for s in _snakes:
					board += "%s  %d\n" % [str(s.species.get("display_name", s.name)), s.score]
				_hud.set_board(board)
			_maybe_hide_card(local_t, 88.0, 3.0)
		6:
			var u := (_t - 108.0)
			_cam.global_position = Vector3(sin(u * 0.35) * 7.5, 2.2, 8.5 - u * 0.15)
			_cam.look_at(Vector3(0.0, 0.25, 1.0))

func _action_drive(_delta: float) -> void:
	if _hero == null:
		return
	if _strike_cd <= 0.0:
		_hero.begin_strike()
		_strike_cd = 2.6
		Sfx.play_strike()
	if _hero.global_position.length() > 28.0:
		_hero.yaw += 1.8
	for s in _snakes:
		if s != _hero and s.is_bot and randf() < 0.01:
			s.begin_strike()

func _chase_cam(back: float, height: float) -> void:
	if _hero == null:
		return
	_cam.current = true
	if _hero.camera:
		_hero.camera.current = false
	var back_dir := _hero.global_transform.basis.z
	_cam.global_position = _hero.global_position + Vector3(0.0, height, 0.0) + back_dir * back
	_cam.look_at(_hero.global_position + Vector3(0.0, 0.15, 0.0))

func _orbit_cam(radius: float, height: float, ang: float) -> void:
	if _hero == null:
		return
	_cam.current = true
	if _hero.camera:
		_hero.camera.current = false
	var p := _hero.global_position
	_cam.global_position = p + Vector3(sin(ang) * radius, height, cos(ang) * radius)
	_cam.look_at(p + Vector3(0.0, 0.2, 0.0))

func _smash_zoom() -> void:
	if _hero == null:
		return
	_cam.global_position = _cam.global_position.lerp(_hero.global_position + Vector3(0.4, 0.35, 0.9), 0.35)

func _maybe_hide_card(t: float, start: float, hold: float) -> void:
	if t > start + hold:
		_title.visible = false
		_sub.visible = false

func _spawn(species_id: String, origin: Vector3, yaw: float, first_person: bool) -> SnakeActor:
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
	_snakes.append(s)
	return s

func _pose_wave(s: SnakeActor) -> void:
	if s.body == null:
		return
	var trail := PackedVector3Array()
	for i in 42:
		var z := s.global_position.z - float(i) * 0.09
		var x := s.global_position.x + sin(float(i) * 0.2) * 0.28
		trail.append(Vector3(x, 0.08, z))
	s.body.trail = trail
	s.global_position = trail[0]
	s.body.follow(s.global_position, s.length_m, s._sf("radius", 0.07), s._sf("undulation_amp", 0.04), s._sf("undulation_freq", 8.0), 0.016)

func _spawn_food(origin: Vector3, kind: int) -> void:
	var p: Prey = PREY_SCENE.instantiate()
	add_child(p)
	_food_id += 1
	p.setup(_food_id, origin, kind)

func _wipe_world(keep_cam: bool) -> void:
	GameState.local_paused = false
	_hero = null
	_snakes.clear()
	_hud = null
	Sfx.stop_ambient()
	for c in get_children():
		if c == _cam:
			continue
		if c.name == "Cards":
			for card_child in c.get_children():
				if card_child is ColorRect:
					card_child.queue_free()
			continue
		c.queue_free()
	_cam.current = keep_cam
	_cam.fov = 72.0

func _build_cards() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Cards"
	layer.layer = 80
	add_child(layer)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.position = Vector2(-480, 48)
	_title.size = Vector2(960, 90)
	_title.add_theme_font_size_override("font_size", 56)
	_title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.42))
	_title.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.03))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_sub.position = Vector2(-480, 130)
	_sub.size = Vector2(960, 48)
	_sub.add_theme_font_size_override("font_size", 22)
	_sub.add_theme_color_override("font_color", Color(0.82, 0.86, 0.7))
	_sub.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.03))
	_sub.add_theme_constant_override("outline_size", 6)
	layer.add_child(_sub)

func _set_card(title: String, sub: String) -> void:
	_title.text = title
	_sub.text = sub
	_title.visible = title != ""
	_sub.visible = sub != ""
