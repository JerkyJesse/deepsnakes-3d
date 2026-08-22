class_name BiomeBuilder
extends RefCounted

const HALF := 42.0

static func build(world: Node3D, biome: Dictionary) -> void:
	_environment(world, biome)
	_sun(world, biome)
	_ground(world, biome)
	_walls(world, biome)
	_rocks(world, biome)
	if biome.has_grass:
		_grass(world, biome)
	if biome.has_water:
		_water(world, biome)

static func _environment(world: Node3D, biome: Dictionary) -> void:
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = biome.sky_top
	sky.sky_horizon_color = biome.sky_horizon
	sky.ground_bottom_color = biome.ground_a
	sky.ground_horizon_color = biome.sky_horizon
	sky.sun_angle_max = 30.0
	var sky_tex := Sky.new()
	sky_tex.sky_material = sky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky_tex
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = biome.ambient
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.fog_enabled = true
	env.fog_light_color = biome.fog_color
	env.fog_density = biome.fog_density
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = biome.fog_density * 0.45
	env.volumetric_fog_albedo = biome.fog_color
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

static func _sun(world: Node3D, biome: Dictionary) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = biome.sun_color
	sun.light_energy = biome.sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	sun.rotation_degrees = biome.sun_rotation
	world.add_child(sun)

static func _ground(world: Node3D, biome: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(HALF * 2.0, 1.0, HALF * 2.0)
	mesh.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ground.gdshader")
	mat.set_shader_parameter("col_a", biome.ground_a)
	mat.set_shader_parameter("col_b", biome.ground_b)
	mat.set_shader_parameter("use_photo", 0.0)
	var biome_id: String = str(biome.get("id", "forest"))
	var photo: String = "res://assets/photogrammetry/%s/diff.jpg" % biome_id
	if ResourceLoader.exists(photo):
		mat.set_shader_parameter("photo_albedo", load(photo))
		mat.set_shader_parameter("use_photo", 1.0)
		var nrm: String = "res://assets/photogrammetry/%s/nor.jpg" % biome_id
		var rgh: String = "res://assets/photogrammetry/%s/rough.jpg" % biome_id
		if ResourceLoader.exists(nrm):
			mat.set_shader_parameter("photo_normal", load(nrm))
		if ResourceLoader.exists(rgh):
			mat.set_shader_parameter("photo_rough", load(rgh))
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(body)

static func _walls(world: Node3D, biome: Dictionary) -> void:
	var thick := 2.0
	var tall := 6.0
	var specs := [
		Vector3(0.0, tall * 0.5, HALF + thick * 0.5), Vector3(HALF * 2.0 + 4.0, tall, thick),
		Vector3(0.0, tall * 0.5, -HALF - thick * 0.5), Vector3(HALF * 2.0 + 4.0, tall, thick),
		Vector3(HALF + thick * 0.5, tall * 0.5, 0.0), Vector3(thick, tall, HALF * 2.0 + 4.0),
		Vector3(-HALF - thick * 0.5, tall * 0.5, 0.0), Vector3(thick, tall, HALF * 2.0 + 4.0),
	]
	var i := 0
	while i < specs.size():
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = specs[i + 1]
		col.shape = shape
		body.add_child(col)
		body.position = specs[i]
		world.add_child(body)
		i += 2
	_wall_dressing(world, biome)

static func _wall_dressing(world: Node3D, biome: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var mat := StandardMaterial3D.new()
	mat.albedo_color = biome.rock_color
	mat.roughness = 0.88
	var hedge := StandardMaterial3D.new()
	hedge.albedo_color = Color(biome.grass_color.r * 0.7, biome.grass_color.g * 0.7, biome.grass_color.b * 0.7)
	hedge.roughness = 0.92
	var id: String = str(biome.get("id", "forest"))
	var use_hedge: bool = id == "forest" or id == "swamp"
	for n in 56:
		var t := float(n) / 56.0 * TAU
		var r := HALF - 1.2
		var pos := Vector3(cos(t) * r, 0.0, sin(t) * r)
		var inst := MeshInstance3D.new()
		if use_hedge:
			var cap := CapsuleMesh.new()
			cap.radius = rng.randf_range(0.35, 0.7)
			cap.height = rng.randf_range(1.6, 3.2)
			inst.mesh = cap
			inst.material_override = hedge
			inst.position = pos + Vector3(0.0, cap.height * 0.35, 0.0)
		else:
			var box := BoxMesh.new()
			box.size = Vector3(rng.randf_range(0.8, 2.2), rng.randf_range(1.2, 3.4), rng.randf_range(0.8, 2.2))
			inst.mesh = box
			inst.material_override = mat
			inst.position = pos + Vector3(0.0, box.size.y * 0.4, 0.0)
		world.add_child(inst)

static func _rocks(world: Node3D, biome: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var mat := StandardMaterial3D.new()
	mat.albedo_color = biome.rock_color
	mat.roughness = 0.9
	for i in 22:
		var inst := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.4, 1.6)
		sm.height = sm.radius * rng.randf_range(0.8, 1.6)
		inst.mesh = sm
		inst.material_override = mat
		inst.position = Vector3(rng.randf_range(-36.0, 36.0), sm.height * 0.25, rng.randf_range(-36.0, 36.0))
		inst.scale = Vector3(rng.randf_range(0.8, 1.6), rng.randf_range(0.4, 0.9), rng.randf_range(0.8, 1.6))
		world.add_child(inst)
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = sm.radius * 0.7
		col.shape = sph
		body.add_child(col)
		body.position = inst.position
		world.add_child(body)

static func _grass(world: Node3D, biome: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1))
	st.add_vertex(Vector3(-0.02, 0.0, 0.0))
	st.add_vertex(Vector3(0.02, 0.0, 0.0))
	st.add_vertex(Vector3(0.0, 0.35, 0.0))
	var blade := st.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade
	mm.instance_count = 2200
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in mm.instance_count:
		var x := rng.randf_range(-38.0, 38.0)
		var z := rng.randf_range(-38.0, 38.0)
		var xf := Transform3D()
		xf = xf.scaled(Vector3(rng.randf_range(0.7, 1.4), rng.randf_range(0.6, 1.5), 1.0))
		xf = xf.rotated(Vector3.UP, rng.randf() * TAU)
		xf.origin = Vector3(x, 0.0, z)
		mm.set_instance_transform(i, xf)
		mm.set_instance_color(i, Color(rng.randf(), rng.randf(), 0.0))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	var gmat := ShaderMaterial.new()
	gmat.shader = load("res://shaders/grass.gdshader")
	gmat.set_shader_parameter("grass_color", biome.grass_color)
	inst.material_override = gmat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(inst)

static func _water(world: Node3D, _biome: Dictionary) -> void:
	var inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(28.0, 18.0)
	inst.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader")
	inst.material_override = mat
	inst.position = Vector3(12.0, 0.04, -8.0)
	world.add_child(inst)
