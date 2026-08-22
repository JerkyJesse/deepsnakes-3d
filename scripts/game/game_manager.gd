extends Node3D

const SNAKE := preload("res://scenes/snake/player_snake.tscn")
const ENEMY := preload("res://scenes/snake/enemy_snake.tscn")
const PREY_SCENE := preload("res://scenes/game/prey.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PREY_COUNT := 10
const BOT_COUNT := 3
const NECK := 1.45
const RESPAWN := 4.0
const BIOME_SCENES := {
	"forest": "res://scenes/biomes/forest.tscn",
	"desert": "res://scenes/biomes/desert.tscn",
	"swamp": "res://scenes/biomes/swamp.tscn",
	"canyon": "res://scenes/biomes/canyon.tscn",
}

var players: Node3D
var prey_root: Node3D
var hud: Hud
var _bot_serial := 0
var _prey_serial := 0
var _dead_until: Dictionary = {}
var _paused := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if multiplayer.multiplayer_peer == null:
		Network.start_offline()
	var biome_path: String = str(BIOME_SCENES.get(GameState.biome_id, BIOME_SCENES["forest"]))
	add_child(load(biome_path).instantiate())
	Sfx.start_ambient()
	players = Node3D.new()
	players.name = "Players"
	add_child(players)
	prey_root = Node3D.new()
	prey_root.name = "Prey"
	add_child(prey_root)
	hud = HUD_SCENE.instantiate() as Hud
	add_child(hud)
	hud.setup_world(get_world_3d())
	var fallback := Camera3D.new()
	fallback.name = "LobbyCam"
	fallback.position = Vector3(0.0, 18.0, 22.0)
	fallback.current = true
	add_child(fallback)
	fallback.look_at(Vector3.ZERO)
	Network.peer_disconnected.connect(_on_peer_left)
	Network.disconnected.connect(_on_host_gone)
	if multiplayer.is_server():
		var id := multiplayer.get_unique_id()
		rpc_spawn_player.rpc("p_%d" % id, GameState.species_id, _slot(0), false, id)
		for i in BOT_COUNT:
			var sid: String = str(SpeciesCatalog.all()[_rng.randi() % 4]["id"])
			_bot_serial += 1
			rpc_spawn_player.rpc("bot_%d" % _bot_serial, sid, _slot(i + 3), true, 1)
		for i in PREY_COUNT:
			_prey_serial += 1
			rpc_spawn_prey.rpc(_prey_serial, _rand_food(), _prey_kind())
	else:
		register_player.rpc_id(1, GameState.species_id)

func _process(delta: float) -> void:
	var local := _local_snake()
	var hint := ""
	if GameState.mode == GameState.Mode.HOST:
		var ips := Network.lan_ips()
		hint = "Listen server  port %d  %s" % [Network.port, ", ".join(ips) if not ips.is_empty() else "localhost"]
	elif GameState.mode == GameState.Mode.CLIENT:
		hint = "Connected to host"
	else:
		hint = "Offline"
	if local:
		hud.set_local(local.score, local.length_m, ScoreService.high_score, hint, local.stamina, local.striking, local.is_swallowing())
		hud.update_minimap(local.global_position, local.yaw)
		ScoreService.submit(local.score)
		if local.is_dead:
			var left: float = float(_dead_until.get(local.name, 0.0))
			hud.show_death(local.score, maxf(0.0, left))
		else:
			hud.hide_death()
	var board := ""
	for s in players.get_children():
		if s is SnakeActor:
			board += "%s  %d\n" % [str(s.species.get("display_name", s.name)), s.score]
	hud.set_board(board)
	if multiplayer.is_server():
		if GameState.local_paused and GameState.mode == GameState.Mode.OFFLINE:
			return
		_server_sim(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _paused and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
		_leave()
		get_viewport().set_input_as_handled()
		return
	if _paused and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_pause(false)
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	_set_pause(not _paused)

func _set_pause(on: bool) -> void:
	_paused = on
	GameState.local_paused = on
	hud.set_paused(on)
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		get_tree().paused = false
		var local := _local_snake()
		if local and not local.is_dead:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _leave() -> void:
	GameState.local_paused = false
	Sfx.stop_ambient()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Network.shutdown()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _on_host_gone() -> void:
	_leave()

func _on_peer_left(id: int) -> void:
	if not multiplayer.is_server():
		return
	rpc_despawn.rpc("p_%d" % id)

func _server_sim(delta: float) -> void:
	for key in _dead_until.keys():
		_dead_until[key] = float(_dead_until[key]) - delta
		if float(_dead_until[key]) <= 0.0:
			var node := players.get_node_or_null(str(key))
			_dead_until.erase(key)
			if node is SnakeActor:
				rpc_revive.rpc(node.name, _slot(_rng.randi() % 8))
	var snakes: Array[SnakeActor] = []
	for c in players.get_children():
		if c is SnakeActor:
			snakes.append(c)
	for s in snakes:
		if s.is_dead:
			continue
		for food in prey_root.get_children():
			if food is Prey and s.global_position.distance_to(food.global_position) < s.eat_range():
				s.eat_gain(0.55, 1)
				rpc_move_prey.rpc(food.prey_id, _rand_food())
		if _hits_self(s):
			_kill_snake(s)
			continue
		for other in snakes:
			if other == s or other.is_dead:
				continue
			if _head_hits_body(s, other):
				if s.length_m + 0.15 >= other.length_m:
					s.eat_gain(minf(2.5, other.length_m * 0.25), 5)
					_kill_snake(other)
				else:
					_kill_snake(s)
				break

func _hits_self(s: SnakeActor) -> bool:
	if s.body == null:
		return false
	var r: float = s._sf("radius", 0.07) * 1.15
	for p in s.body.hit_points(NECK):
		if s.global_position.distance_to(p) < r:
			return true
	return false

func _head_hits_body(a: SnakeActor, b: SnakeActor) -> bool:
	if b.body == null:
		return false
	var r: float = (a._sf("radius", 0.07) + b._sf("radius", 0.07)) * 1.1
	for p in b.body.hit_points(NECK * 0.65):
		if a.global_position.distance_to(p) < r:
			return true
	return false

func _kill_snake(s: SnakeActor) -> void:
	if s.is_dead:
		return
	s.kill()
	_dead_until[s.name] = RESPAWN
	rpc_kill.rpc(s.name)

func _slot(i: int) -> Vector3:
	var ang := float(i) * TAU / 8.0
	return Vector3(cos(ang) * 16.0, 0.12, sin(ang) * 16.0)

func _rand_food() -> Vector3:
	return Vector3(_rng.randf_range(-30.0, 30.0), 0.12, _rng.randf_range(-30.0, 30.0))

func _prey_kind() -> int:
	match GameState.biome_id:
		"swamp":
			return Prey.Kind.FROG if _rng.randf() < 0.7 else Prey.Kind.RODENT
		"canyon":
			return Prey.Kind.EGG if _rng.randf() < 0.55 else Prey.Kind.RODENT
		"desert":
			return Prey.Kind.RODENT if _rng.randf() < 0.75 else Prey.Kind.EGG
		_:
			return Prey.Kind.RODENT if _rng.randf() < 0.7 else Prey.Kind.EGG

func _local_snake() -> SnakeActor:
	for c in players.get_children():
		if c is SnakeActor and c.is_multiplayer_authority() and not c.is_bot:
			return c
	return null

@rpc("any_peer", "reliable")
func register_player(species_id: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	var n := "p_%d" % id
	if players.has_node(n):
		return
	rpc_spawn_player.rpc(n, species_id, _slot(id % 8), false, id)
	for c in players.get_children():
		if c.name == n:
			continue
		if c is SnakeActor:
			rpc_spawn_player.rpc_id(id, c.name, c.species_id, c.global_position, c.is_bot, 1 if c.is_bot else int(str(c.name).get_slice("_", 1)))
	for food in prey_root.get_children():
		if food is Prey:
			rpc_spawn_prey.rpc_id(id, food.prey_id, food.global_position, food.kind)

@rpc("authority", "reliable", "call_local")
func rpc_spawn_player(node_name: String, species_id: String, origin: Vector3, is_bot: bool, authority: int) -> void:
	if players.has_node(node_name):
		return
	var s: SnakeActor = (ENEMY if is_bot else SNAKE).instantiate()
	s.name = node_name
	s.species_id = species_id
	s.is_bot = is_bot
	players.add_child(s, true)
	s.set_multiplayer_authority(authority)
	s.global_position = origin
	s.yaw = atan2(-origin.x, -origin.z)
	s.configure()
	var lobby := get_node_or_null("LobbyCam") as Camera3D
	if lobby and s.camera and s.camera.current:
		lobby.current = false

@rpc("authority", "reliable", "call_local")
func rpc_spawn_prey(id: int, origin: Vector3, kind: int = 0) -> void:
	var n := "prey_%d" % id
	if prey_root.has_node(n):
		return
	var p: Prey = PREY_SCENE.instantiate() as Prey
	prey_root.add_child(p, true)
	p.setup(id, origin, kind)

@rpc("authority", "reliable", "call_local")
func rpc_move_prey(id: int, origin: Vector3) -> void:
	var n := prey_root.get_node_or_null("prey_%d" % id)
	if n is Prey:
		n.global_position = origin

@rpc("authority", "reliable", "call_local")
func rpc_kill(node_name: String) -> void:
	var n := players.get_node_or_null(node_name)
	if n is SnakeActor and not n.is_dead:
		n.kill()

@rpc("authority", "reliable", "call_local")
func rpc_revive(node_name: String, origin: Vector3) -> void:
	var n := players.get_node_or_null(node_name)
	if n is SnakeActor:
		n.revive(origin)

@rpc("authority", "reliable", "call_local")
func rpc_despawn(node_name: String) -> void:
	var n := players.get_node_or_null(node_name)
	if n:
		n.queue_free()
