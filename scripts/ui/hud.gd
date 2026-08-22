class_name Hud
extends CanvasLayer

var score_label: Label
var length_label: Label
var status_label: Label
var high_label: Label
var board_label: Label
var stamina_bar: ProgressBar
var death_panel: Panel
var pause_panel: Panel
var death_text: Label
var _vig_mat: ShaderMaterial
var _mini_wrap: SubViewportContainer
var _mini_vp: SubViewport
var _mini_cam: Camera3D
var _blink_t := 0.0

func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vig_mat = ShaderMaterial.new()
	_vig_mat.shader = load("res://shaders/fp_vignette.gdshader")
	vig.material = _vig_mat
	root.add_child(vig)

	score_label = _label(root, Vector2(24, 18), 28)
	length_label = _label(root, Vector2(24, 52), 20)
	high_label = _label(root, Vector2(24, 80), 18)
	status_label = _label(root, Vector2(24, 108), 16)
	board_label = _label(root, Vector2(24, 140), 16)
	board_label.modulate = Color(0.85, 0.8, 0.65)

	var stam_l := _label(root, Vector2(24, 248), 14)
	stam_l.text = "Stamina"
	stamina_bar = ProgressBar.new()
	stamina_bar.position = Vector2(24, 268)
	stamina_bar.size = Vector2(220, 16)
	stamina_bar.max_value = 1.0
	stamina_bar.value = 1.0
	stamina_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.78, 0.58, 0.18)
	stamina_bar.add_theme_stylebox_override("fill", fill)
	root.add_child(stamina_bar)

	_mini_wrap = SubViewportContainer.new()
	_mini_wrap.stretch = true
	_mini_wrap.custom_minimum_size = Vector2(200, 200)
	_mini_wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_mini_wrap.position = Vector2(-224, 24)
	_mini_wrap.size = Vector2(200, 200)
	_mini_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_mini_wrap)
	_mini_vp = SubViewport.new()
	_mini_vp.size = Vector2i(200, 200)
	_mini_vp.disable_3d = false
	_mini_vp.msaa_3d = Viewport.MSAA_DISABLED
	_mini_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_mini_wrap.add_child(_mini_vp)
	_mini_cam = Camera3D.new()
	_mini_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_mini_cam.size = 38.0
	_mini_cam.near = 0.2
	_mini_cam.far = 80.0
	_mini_cam.current = true
	_mini_vp.add_child(_mini_cam)

	var hint := _label(root, Vector2(24, 860), 14)
	hint.text = "Mouse steer   W boost   S slow   A/D turn   Space strike   Esc pause"
	hint.modulate = Color(0.75, 0.72, 0.6, 0.8)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(24, -40)

	death_panel = _overlay(root, "You died")
	death_text = death_panel.get_node("Msg") as Label
	pause_panel = _overlay(root, "Paused\nClick to resume    Q menu")
	death_panel.visible = false
	pause_panel.visible = false

func setup_world(world: World3D) -> void:
	if _mini_vp:
		_mini_vp.world_3d = world

func _label(parent: Control, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.93, 0.88, 0.72))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.04))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l

func _overlay(parent: Control, text: String) -> Panel:
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.size = Vector2(520, 180)
	p.position = Vector2(-260, -90)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.05, 0.88)
	style.set_border_width_all(2)
	style.border_color = Color(0.78, 0.58, 0.18)
	p.add_theme_stylebox_override("panel", style)
	var msg := Label.new()
	msg.name = "Msg"
	msg.text = text
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.set_anchors_preset(Control.PRESET_FULL_RECT)
	msg.add_theme_font_size_override("font_size", 28)
	msg.add_theme_color_override("font_color", Color(0.95, 0.86, 0.55))
	p.add_child(msg)
	parent.add_child(p)
	return p

func set_local(score: int, length_m: float, high: int, host_hint: String, p_stamina: float, striking: bool, eating: bool) -> void:
	score_label.text = "Score  %d" % score
	length_label.text = "Length  %.1fm" % length_m
	high_label.text = "Best  %d" % high
	status_label.text = host_hint
	stamina_bar.value = p_stamina
	_blink_t += 0.016
	var blink := 1.0 if fmod(_blink_t, 4.8) < 0.12 else 0.0
	if _vig_mat:
		_vig_mat.set_shader_parameter("blink", blink)
		var jaw: float = 0.0
		if striking:
			jaw = 0.85
		elif eating:
			jaw = 0.55
		_vig_mat.set_shader_parameter("jaw", jaw)

func update_minimap(pos: Vector3, yaw: float) -> void:
	if _mini_cam == null:
		return
	_mini_cam.global_position = Vector3(pos.x, 32.0, pos.z)
	_mini_cam.rotation = Vector3(-PI * 0.5, yaw, 0.0)

func set_board(lines: String) -> void:
	board_label.text = lines

func show_death(score: int, respawn_in: float) -> void:
	death_panel.visible = true
	if respawn_in > 0.05:
		death_text.text = "You died\nScore %d\nRespawn in %.0fs" % [score, respawn_in]
	else:
		death_text.text = "You died\nScore %d\nRespawning..." % score

func hide_death() -> void:
	death_panel.visible = false

func set_paused(on: bool) -> void:
	pause_panel.visible = on
