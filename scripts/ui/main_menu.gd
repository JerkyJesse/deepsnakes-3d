extends Control

const WORLD := "res://scenes/game/world.tscn"

var _species_id: String = "ball_python"
var _biome_id: String = "forest"
var _status: Label
var _ip: LineEdit
var _sens: HSlider
var _fov: HSlider
var _vol: HSlider

func _ready() -> void:
	_species_id = GameState.species_id
	_biome_id = GameState.biome_id
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Network.connected.connect(_on_joined)
	Network.connection_failed.connect(func() -> void: _status.text = "Could not reach host.")

func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var smat := ShaderMaterial.new()
	smat.shader = load("res://shaders/menu_scales.gdshader")
	bg.material = smat
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	margin.add_child(v)

	var title := Label.new()
	title.text = "DEEP SNAKES"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.93, 0.82, 0.42))
	v.add_child(title)
	var sub := Label.new()
	sub.text = "First person  ·  Listen server"
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.72, 0.78, 0.62))
	v.add_child(sub)

	v.add_child(_heading("Species"))
	v.add_child(_row_buttons(SpeciesCatalog.all(), "id", "display_name", _species_id, func(id: String) -> void: _species_id = id))

	v.add_child(_heading("Biome"))
	v.add_child(_row_buttons(BiomeCatalog.all(), "id", "display_name", _biome_id, func(id: String) -> void: _biome_id = id))

	v.add_child(_heading("Play"))
	var play := HBoxContainer.new()
	play.add_theme_constant_override("separation", 12)
	play.add_child(_btn("Offline", _play_offline))
	play.add_child(_btn("Host listen server", _play_host))
	play.add_child(_btn("Join", _play_join))
	v.add_child(play)

	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 8)
	var host_l := Label.new()
	host_l.text = "Host"
	host_l.add_theme_color_override("font_color", Color(0.85, 0.82, 0.7))
	join_row.add_child(host_l)
	_ip = LineEdit.new()
	_ip.text = GameState.join_ip
	_ip.placeholder_text = ""
	_ip.custom_minimum_size = Vector2(220, 0)
	join_row.add_child(_ip)
	v.add_child(join_row)

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	_status.text = _host_hint()
	v.add_child(_status)

	v.add_child(_heading("Options"))
	_sens = _slider_row(v, "Mouse look", Settings.mouse_sensitivity, 0.0006, 0.006)
	_fov = _slider_row(v, "FOV", Settings.fov, 70.0, 100.0)
	_vol = _slider_row(v, "Volume", Settings.master_volume, 0.0, 1.0)

	var bottom := HBoxContainer.new()
	bottom.add_child(_btn("Quit", func() -> void: get_tree().quit()))
	v.add_child(bottom)

func _heading(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.78, 0.58, 0.22))
	return l

func _row_buttons(items: Array, id_key: String, name_key: String, current: String, cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for item in items:
		var id: String = item[id_key]
		var b := Button.new()
		b.text = item[name_key]
		b.toggle_mode = true
		b.button_pressed = id == current
		b.pressed.connect(func() -> void:
			Sfx.play_click()
			cb.call(id)
			for c in row.get_children():
				if c is Button:
					c.button_pressed = c == b
		)
		row.add_child(b)
	return row

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 40)
	b.pressed.connect(func() -> void:
		Sfx.play_click()
		cb.call()
	)
	return b

func _slider_row(parent: VBoxContainer, caption: String, value: float, mn: float, mx: float) -> HSlider:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = caption
	l.custom_minimum_size = Vector2(140, 0)
	l.add_theme_color_override("font_color", Color(0.85, 0.82, 0.7))
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = (mx - mn) / 100.0
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(s)
	parent.add_child(row)
	return s

func _commit_settings() -> void:
	Settings.mouse_sensitivity = _sens.value
	Settings.fov = _fov.value
	Settings.master_volume = _vol.value
	Settings.save_to_disk()
	GameState.species_id = _species_id
	GameState.biome_id = _biome_id
	GameState.join_ip = _ip.text.strip_edges()

func _play_offline() -> void:
	_commit_settings()
	Network.start_offline()
	get_tree().change_scene_to_file(WORLD)

func _play_host() -> void:
	_commit_settings()
	var err := Network.host_listen(GameState.join_port)
	if err != OK:
		_status.text = "Could not host (port in use?)."
		return
	get_tree().change_scene_to_file(WORLD)

func _play_join() -> void:
	_commit_settings()
	_status.text = "Connecting..."
	var err := Network.join(GameState.join_ip, GameState.join_port)
	if err != OK:
		_status.text = "Join failed to start."

func _on_joined() -> void:
	get_tree().change_scene_to_file(WORLD)

func _host_hint() -> String:
	return "Listen server uses port 7777."
