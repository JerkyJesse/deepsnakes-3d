class_name EnemyBrain
extends RefCounted

static func tick(snake: SnakeActor, delta: float) -> void:
	if snake.is_dead:
		return
	var pos := snake.global_position
	var target := _nearest_food(snake)
	if target == Vector3.ZERO:
		target = Vector3(sin(Time.get_ticks_msec() * 0.0004 + pos.x), 0.0, cos(Time.get_ticks_msec() * 0.0003 + pos.z)) * 12.0
	var to := target - pos
	to.y = 0.0
	if pos.length() > 32.0:
		to = -pos
		to.y = 0.0
	if to.length() < 0.05:
		return
	to = to.normalized()
	var desired := atan2(-to.x, -to.z)
	snake.yaw = lerp_angle(snake.yaw, desired, snake._sf("turn_rate", 2.4) * 0.85 * delta)
	if pos.distance_to(target) < 2.2 and fmod(Time.get_ticks_msec() / 1000.0, 3.0) < 0.25:
		snake.begin_strike()

static func _nearest_food(snake: SnakeActor) -> Vector3:
	var best := Vector3.ZERO
	var best_d := 1.0e9
	for n in snake.get_tree().get_nodes_in_group("food"):
		if n is Node3D:
			var d: float = snake.global_position.distance_to(n.global_position)
			if d < best_d:
				best_d = d
				best = n.global_position
	return best
