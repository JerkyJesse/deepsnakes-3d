class_name SnakeActor
extends CharacterBody3D

signal died(actor: SnakeActor)
signal scored(amount: int)

@export var species_id: String = "ball_python"
@export var is_bot: bool = false
@export var cinematic: bool = false
@export var length_m: float = 3.8
@export var striking: bool = false
@export var is_dead: bool = false
@export var score: int = 0
@export var stamina: float = 1.0
var forced_boost: bool = false

var species: Dictionary
var yaw: float = 0.0
var body: SnakeBody
var camera: Camera3D
var _strike_left := 0.0
var _blink := 0.0
var _tongue: MeshInstance3D
var _fp_tongue: MeshInstance3D
var _head_vis: Node3D
var _eat_cool := 0.0
var _respawn_locked := 0.0
var _hiss_cd := 2.5
var _cam_base := Vector3.ZERO

func configure() -> void:
	species = SpeciesCatalog.get_species(species_id)
	length_m = _sf("start_length", 3.8)
	_build_nodes()
	add_to_group("snakes")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.2
	if body:
		body.seed_trail(global_position, global_transform.basis.z, length_m)

func _build_nodes() -> void:
	if has_node("Col"):
		return
	var col := CollisionShape3D.new()
	col.name = "Col"
	var sph := SphereShape3D.new()
	sph.radius = _sf("radius", 0.07) * 1.4
	col.shape = sph
	add_child(col)

	body = SnakeBody.new()
	body.name = "Body"
	add_child(body)
	body.setup(species)

	_head_vis = Node3D.new()
	_head_vis.name = "HeadVis"
	add_child(_head_vis)
	_make_head()

	camera = Camera3D.new()
	camera.name = "Eye"
	camera.fov = Settings.fov
	camera.near = 0.03
	camera.far = 220.0
	_cam_base = Vector3(0.0, _sf("radius", 0.07) * 0.55, 0.03)
	camera.position = _cam_base
	camera.current = cinematic or (is_multiplayer_authority() and not is_bot)
	add_child(camera)
	_head_vis.visible = not camera.current
	if camera.current:
		if not cinematic:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_make_fp_mouth()

func _make_head() -> void:
	var mat: Material = body.material_override
	var rad := _sf("radius", 0.07)
	var skull := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = rad * 1.15
	sm.height = rad * 2.1
	skull.mesh = sm
	skull.material_override = mat
	_head_vis.add_child(skull)
	var snout := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rad * 1.1, rad * 0.7, rad * 1.6)
	snout.mesh = box
	snout.position = Vector3(0.0, -rad * 0.15, -rad * 1.1)
	snout.material_override = mat
	_head_vis.add_child(snout)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = rad * 0.22
		eye.mesh = em
		eye.position = Vector3(side * rad * 0.55, rad * 0.25, -rad * 0.55)
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color(0.05, 0.12, 0.04)
		emat.roughness = 0.15
		emat.metallic = 0.2
		eye.material_override = emat
		_head_vis.add_child(eye)
	_tongue = MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.008, 0.004, rad * 1.8)
	_tongue.mesh = tm
	_tongue.position = Vector3(0.0, -rad * 0.1, -rad * 1.7)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.72, 0.18, 0.22)
	_tongue.material_override = tmat
	_head_vis.add_child(_tongue)

func _make_fp_mouth() -> void:
	_fp_tongue = MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.012, 0.004, 0.16)
	_fp_tongue.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.72, 0.18, 0.22)
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fp_tongue.material_override = tmat
	_fp_tongue.position = Vector3(0.0, -0.04, -0.14)
	camera.add_child(_fp_tongue)

func _unhandled_input(event: InputEvent) -> void:
	if is_bot or is_dead or not is_multiplayer_authority() or GameState.local_paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * Settings.mouse_sensitivity

func _physics_process(delta: float) -> void:
	if species.is_empty():
		return
	_eat_cool = maxf(0.0, _eat_cool - delta)
	_respawn_locked = maxf(0.0, _respawn_locked - delta)
	_blink += delta
	_hiss_cd -= delta
	if _hiss_cd <= 0.0 and is_multiplayer_authority() and not is_bot and not is_dead:
		Sfx.play_hiss()
		_hiss_cd = randf_range(4.5, 9.0)
	if is_dead:
		if camera and camera.current:
			camera.position = camera.position.lerp(Vector3(0.0, 1.4, 2.2), 2.0 * delta)
		return
	if is_bot:
		if GameState.local_paused and GameState.mode == GameState.Mode.OFFLINE:
			return
		if multiplayer.is_server():
			EnemyBrain.tick(self, delta)
			_simulate(delta)
			_broadcast()
	elif is_multiplayer_authority():
		if not GameState.local_paused:
			_read_keys(delta)
			_simulate(delta)
		_broadcast()
	if body:
		body.follow(global_position, length_m, _sf("radius", 0.07), _sf("undulation_amp", 0.04), _sf("undulation_freq", 8.0), delta)
	var flick := 1.0 if fmod(_blink, 2.4) < 0.18 else 0.15
	if _tongue:
		_tongue.scale = Vector3(1.0, 1.0, flick)
	if _fp_tongue:
		_fp_tongue.scale = Vector3(1.0, 1.0, flick)
		_fp_tongue.position.z = -0.14 - (0.05 if striking else 0.0)
	if camera and camera.current and not is_dead:
		var freq := _sf("undulation_freq", 8.0)
		var amp := _sf("undulation_amp", 0.04)
		var bob := sin(_blink * freq) * amp * 0.55
		camera.position = _cam_base + Vector3(0.0, bob, 0.0)
		camera.rotation.z = sin(_blink * freq * 0.7) * 0.025
		if striking:
			camera.position.z -= 0.04

func _read_keys(delta: float) -> void:
	if Input.is_action_pressed("steer_left"):
		yaw += _sf("turn_rate", 2.4) * 0.9 * delta
	if Input.is_action_pressed("steer_right"):
		yaw -= _sf("turn_rate", 2.4) * 0.9 * delta
	if Input.is_action_just_pressed("strike"):
		begin_strike()
	_strike_left = maxf(0.0, _strike_left - delta)
	striking = _strike_left > 0.0

func begin_strike() -> void:
	if is_dead:
		return
	_strike_left = 0.28
	striking = true
	if is_multiplayer_authority():
		Sfx.play_strike()

func _simulate(delta: float) -> void:
	var speed: float = _sf("speed", 3.4)
	var boosting := false
	if not is_bot:
		if Input.is_action_pressed("move_back"):
			speed *= 0.55
		boosting = Input.is_action_pressed("boost") or Input.is_action_pressed("move_forward")
		if boosting and stamina > 0.05:
			speed = _sf("burst_speed", 5.6)
			stamina = maxf(0.0, stamina - delta * 0.38)
		else:
			stamina = minf(1.0, stamina + delta * 0.24)
	else:
		if forced_boost and stamina > 0.05:
			speed = _sf("burst_speed", 5.6)
			stamina = maxf(0.0, stamina - delta * 0.38)
		else:
			stamina = minf(1.0, stamina + delta * 0.2)
	if striking:
		speed *= 1.55
	rotation = Vector3(0.0, yaw, 0.0)
	var forward := -global_transform.basis.z
	velocity = forward * speed
	velocity.y = 0.0
	move_and_slide()
	_snap_floor()
	var lim := 39.5
	global_position.x = clampf(global_position.x, -lim, lim)
	global_position.z = clampf(global_position.z, -lim, lim)

func _snap_floor() -> void:
	var from := global_position + Vector3.UP * 2.0
	var to := global_position + Vector3.DOWN * 4.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		global_position.y = hit.position.y + _sf("radius", 0.07)

func eat_gain(amount: float, points: int) -> void:
	length_m = minf(36.0, length_m + amount)
	score += points
	scored.emit(points)
	_eat_cool = 0.22
	stamina = minf(1.0, stamina + 0.12)
	if is_multiplayer_authority() and not is_bot:
		Sfx.play_eat()

func kill(reason: String = "") -> void:
	if is_dead or _respawn_locked > 0.0:
		return
	is_dead = true
	striking = false
	if is_multiplayer_authority() and not is_bot:
		Sfx.play_die()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	died.emit(self)
	if reason != "":
		pass

func revive(origin: Vector3) -> void:
	is_dead = false
	stamina = 1.0
	length_m = _sf("start_length", 3.8)
	global_position = origin
	_respawn_locked = 1.2
	if body:
		body.seed_trail(origin, Vector3.BACK, length_m)
	if camera and is_multiplayer_authority() and not is_bot:
		camera.position = Vector3(0.0, _sf("radius", 0.07) * 0.55, 0.03)
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func eat_range() -> float:
	return _sf("radius", 0.07) * (6.5 if striking else 3.6)

func is_swallowing() -> bool:
	return _eat_cool > 0.0

func _broadcast() -> void:
	rpc_state.rpc(global_position, yaw, length_m, striking, is_dead, score)

@rpc("authority", "unreliable_ordered", "call_remote")
func rpc_state(pos: Vector3, p_yaw: float, len: float, p_strike: bool, dead: bool, p_score: int) -> void:
	if is_multiplayer_authority():
		return
	global_position = global_position.lerp(pos, 0.65)
	yaw = p_yaw
	rotation = Vector3(0.0, yaw, 0.0)
	length_m = len
	striking = p_strike
	score = p_score
	if dead and not is_dead:
		kill()
	elif not dead and is_dead:
		is_dead = false
		if camera:
			camera.position = Vector3(0.0, _sf("radius", 0.07) * 0.55, 0.03)

func _sf(key: String, fallback: float) -> float:
	return float(species.get(key, fallback))
