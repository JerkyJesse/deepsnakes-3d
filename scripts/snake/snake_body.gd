class_name SnakeBody
extends MeshInstance3D

const SPACING := 0.08
const RADIAL := 10

var trail: PackedVector3Array = PackedVector3Array()
var _mat: ShaderMaterial
var _time := 0.0

func setup(species: Dictionary) -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/snake_skin.gdshader")
	_mat.set_shader_parameter("dorsal_color", species.get("dorsal", Color(0.42, 0.28, 0.14)))
	_mat.set_shader_parameter("ventral_color", species.get("ventral", Color(0.78, 0.68, 0.48)))
	_mat.set_shader_parameter("pattern_color", species.get("pattern", Color(0.12, 0.08, 0.04)))
	_mat.set_shader_parameter("pattern_type", int(species.get("pattern_type", 0)))
	_mat.set_shader_parameter("pattern_scale", float(species.get("pattern_scale", 14.0)))
	_mat.set_shader_parameter("scale_scale", float(species.get("scale_scale", 36.0)))
	_mat.set_shader_parameter("wetness", float(species.get("wetness", 0.3)))
	_mat.set_shader_parameter("sss_strength", float(species.get("sss", 0.2)))
	_mat.set_shader_parameter("use_photo", 0.0)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func seed_trail(head: Vector3, back: Vector3, length_m: float) -> void:
	trail = PackedVector3Array()
	var n := maxi(8, int(length_m / SPACING) + 2)
	for i in n:
		trail.append(head + back * SPACING * float(i))

func follow(head: Vector3, length_m: float, radius: float, amp: float, freq: float, delta: float) -> void:
	_time += delta
	if trail.is_empty():
		seed_trail(head, Vector3.BACK, length_m)
	if trail.size() < 2 or trail[0].distance_to(head) >= SPACING:
		trail.insert(0, head)
	else:
		trail[0] = head
	var acc := 0.0
	var keep := 1
	for i in range(1, trail.size()):
		acc += trail[i - 1].distance_to(trail[i])
		keep = i + 1
		if acc >= length_m:
			break
	if trail.size() > keep:
		trail.resize(keep)
	_rebuild(radius, amp, freq, length_m)

func hit_points(neck_m: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var acc := 0.0
	for i in range(1, trail.size()):
		acc += trail[i - 1].distance_to(trail[i])
		if acc >= neck_m:
			out.append(trail[i])
	return out

func _rebuild(radius: float, amp: float, freq: float, length_m: float) -> void:
	var n := trail.size()
	if n < 3:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var dist := 0.0
	for i in n:
		if i > 0:
			dist += trail[i - 1].distance_to(trail[i])
		var tangent: Vector3
		if i == 0:
			tangent = (trail[0] - trail[1]).normalized()
		elif i == n - 1:
			tangent = (trail[i - 1] - trail[i]).normalized()
		else:
			tangent = (trail[i - 1] - trail[i + 1]).normalized()
		if tangent.length() < 0.001:
			tangent = Vector3.FORWARD
		var binorm := Vector3.UP.cross(tangent)
		if binorm.length() < 0.001:
			binorm = Vector3.RIGHT.cross(tangent)
		binorm = binorm.normalized()
		var norm := tangent.cross(binorm).normalized()
		var along := dist / maxf(length_m, 0.01)
		var taper: float = lerpf(1.15, 0.35, smoothstep(0.55, 1.0, along))
		var head_fade: float = smoothstep(0.0, 0.12, along)
		var wave: float = sin(dist * freq + _time * 6.0) * amp * head_fade
		var center: Vector3 = trail[i] + binorm * wave + Vector3.UP * radius * 0.15
		var u := along
		for r in RADIAL:
			var ang := TAU * float(r) / float(RADIAL)
			var dir: Vector3 = (-norm * cos(ang) + binorm * sin(ang)).normalized()
			var p: Vector3 = center + dir * (radius * taper)
			verts.append(p)
			normals.append(dir)
			uvs.append(Vector2(u, float(r) / float(RADIAL)))
		if i > 0:
			var a := (i - 1) * RADIAL
			var b := i * RADIAL
			for r in RADIAL:
				var r2 := (r + 1) % RADIAL
				indices.append(a + r)
				indices.append(b + r)
				indices.append(b + r2)
				indices.append(a + r)
				indices.append(b + r2)
				indices.append(a + r2)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = am
