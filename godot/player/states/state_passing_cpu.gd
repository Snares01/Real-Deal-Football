extends StatePassing
class_name StatePassingCPU

const CATCH_MARGIN := 25.0
const AIM_TARGETS_SIZE := 30

var throw_input := Vector2.RIGHT
var target: Player

var is_throw_advised := true
var throw_wait := randf_range(1.0, 4.0)
var aim_targets: Array[Vector2]

func _ready() -> void:
	super._ready()
	_find_target()
	for i in AIM_TARGETS_SIZE:
		aim_targets.append(Vector2.ZERO)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		throw_arc.update_throw(throw_input)
		var proj_pos: Vector2
		
		
		const LEAD_TIME_REVISIONS := 5
		if target.get_state() is StateRunning:
			var run_state: StateRunning = target.get_state()
			# Get lead time
			var air_time := Ball.time_to_target(player.position, target.position)
			for i in LEAD_TIME_REVISIONS:
				# Revise air_time using position the target will be in at end of throw
				# More loops = more accuracy (test this)
				air_time = Ball.time_to_target(player.position,
				 run_state.calculate_route_pos(air_time))
			proj_pos = run_state.calculate_route_pos(air_time) - player.position
		else:
			proj_pos = (target.position.normalized() * (target.position.length() + CATCH_MARGIN)) - player.position
		aim_targets.push_back(proj_pos)
		aim_targets.pop_front()
		
		# TODO: figure out if throw is advised
		
		# Get average throw from aim_target
		var avg_aim_pos := Vector2.ZERO
		for i in aim_targets.size():
			avg_aim_pos += aim_targets[i]
		avg_aim_pos /= aim_targets.size() 
		throw_input += throw_arc.catch_pos.direction_to(avg_aim_pos) * delta * max(throw_arc.catch_pos.distance_to(proj_pos), 1.0)
		# throw
		throw_wait -= delta
		if throw_wait < 0.0:
			if is_throw_advised:
				player.manager.create_ball(player.position, throw_input)
				end_state()
			else:
				_find_target()
				throw_wait = randf_range(1.0, 2.0)


func _find_target() -> void:
	# TODO: Choose best target
	var receivers := manager.graph.get_role_players(Player.Role.WR, player.on_home_team)
	if not receivers.is_empty():
		target = receivers[randi_range(0, receivers.size() - 1)]
