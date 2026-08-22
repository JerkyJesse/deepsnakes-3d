class_name Prey
extends Area3D

enum Kind { RODENT, FROG, EGG }

var prey_id: int = 0
var kind: int = Kind.RODENT
var _vel: Vector3 = Vector3.ZERO
var _mesh_root: Node3D

func setup(id: int, origin: Vector3, p_kind: int = Kind.RODENT) -> void:
	prey_id = id
	kind = p_kind
	name = "prey_%d" % id
	global_position = origin
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("food")
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.14
	col.shape = sph
	add_child(col)
	_mesh_root = Node3D.new()
	add_child(_mesh_root)
	match kind:
		Kind.FROG:
			_add_blob(Color(0.22, 0.48, 0.18), Vector3(0.16, 0.1, 0.14), Vector3.ZERO)
			_add_blob(Color(0.18, 0.12, 0.08), Vector3(0.05, 0.05, 0.05), Vector3(0.05, 0.08, -0.06))
			_add_blob(Color(0.18, 0.12, 0.08), Vector3(0.05, 0.05, 0.05), Vector3(-0.05, 0.08, -0.06))
		Kind.EGG:
			_add_blob(Color(0.92, 0.88, 0.72), Vector3(0.1, 0.14, 0.1), Vector3(0.0, 0.02, 0.0))
		_:
			_add_blob(Color(0.45, 0.32, 0.18), Vector3(0.18, 0.09, 0.1), Vector3.ZERO)
			_add_blob(Color(0.35, 0.24, 0.14), Vector3(0.08, 0.07, 0.08), Vector3(0.0, 0.02, -0.1))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var ang := rng.randf() * TAU
	var spd := 0.15 if kind == Kind.EGG else rng.randf_range(0.6, 1.4)
	_vel = Vector3(cos(ang), 0.0, sin(ang)) * spd

func _add_blob(color: Color, size: Vector3, offset: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size.x * 0.5
	sm.height = size.y
	mi.mesh = sm
	mi.scale = Vector3(size.x / maxf(sm.radius * 2.0, 0.01), 1.0, size.z / maxf(sm.radius * 2.0, 0.01))
	mi.position = offset
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mi.material_override = mat
	_mesh_root.add_child(mi)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	global_position += _vel * delta
	if absf(global_position.x) > 36.0:
		_vel.x *= -1.0
		global_position.x = clampf(global_position.x, -36.0, 36.0)
	if absf(global_position.z) > 36.0:
		_vel.z *= -1.0
		global_position.z = clampf(global_position.z, -36.0, 36.0)
	global_position.y = 0.12
	if kind != Kind.EGG and randf() < 0.01:
		_vel = _vel.rotated(Vector3.UP, randf_range(-0.8, 0.8))
	if _mesh_root:
		_mesh_root.rotation.y += delta * 1.5
	rpc_pos.rpc(global_position)

@rpc("authority", "unreliable_ordered", "call_remote")
func rpc_pos(p: Vector3) -> void:
	global_position = p
