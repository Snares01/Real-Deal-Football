extends StatePassing
class_name StatePassingCPU

var throw_input := Vector2.RIGHT
var target: Player

var is_throw_advised := false
var throw_wait := randf_range(1.0, 4.0)

func _ready() -> void:
	super._ready()
	_find_target()

func _process(delta: float) -> void:
	if is_instance_valid(target):
		throw_arc.update_throw(throw_input)
		var travel_dist := target.calculate_distance(throw_arc.air_time)
		var target_lead := Vector2.ZERO # How far in front of player to throw
		# lead target along route
		if target.get_state() is StateRunning:
			# Project position based on route being ran
			var target_pos := (target.get_state() as StateRunning).target_pos
			var dist_to_end := target.position.distance_to(target_pos)
			if dist_to_end >= travel_dist:
				# Won't change direction mid-run
				is_throw_advised = true
				target_lead += target.position.direction_to(target_pos) * travel_dist
				# reduce lead the more target_pos is in a different direction
				var ang_diff := (target.velocity.normalized()
					.dot(target.position.direction_to(target_pos)) + 1.0) / 2.0
				#target_lead *= ang_diff
			else:
				# Will change direction / reach end of route mid-run
				is_throw_advised = true
				target_lead += target.position.direction_to(target_pos) * dist_to_end
				travel_dist -= dist_to_end
				if target.get_state().next is StateRunning:
					is_throw_advised = false
					var new_target_pos := (target.get_state().next as StateRunning).target_pos
					target_lead += target_pos.direction_to(new_target_pos) * travel_dist
					# reduce lead the more target_pos is in a different direction
					#var ang_diff := (target.position.direction_to(target_pos)
					#	.dot(target_pos.direction_to(new_target_pos)) + 1.0) / 2.0
					target_pos = new_target_pos
			
			# TODO: add to target_lead if target's x-pos isn't far from own
			var ang_diff: float
			if player.on_home_team:
				ang_diff = target.position.direction_to(target_pos).dot(Vector2.RIGHT)
			else:
				ang_diff = target.position.direction_to(target_pos).dot(Vector2.LEFT)
			# Add target lead if target if running away
			if ang_diff > 0.8:
				if (target.position.x < Globals.scrimmage*Field.Y) == (player.position.x < Globals.scrimmage*Field.Y):
					# more lead if target is behind line of scrimmage
					#print("S")
					target_lead *= 1.25
				else:
					#print("A")
					target_lead *= 0.8
			elif ang_diff > 0.0:
				#print("B")
				target_lead *= 0.7
			elif ang_diff > -0.66:
				#print("C")
				target_lead *= 0.6
			else:
				#print("D")
				target_lead *= 0.5
			# Add lead for greater distance
			#print(player.position.distance_to(target.position) * 0.001)
			#target_lead *= 1.0 + (player.position.distance_to(target.position) * 0.001)
		
		if is_throw_advised:
			# TODO: figure out if throw is advised
			pass
		
		var proj_pos: Vector2 = (target.position - player.position) + target_lead
		#proj_pos *= 1.25
		throw_input += throw_arc.catch_pos.direction_to(proj_pos) * delta * max(throw_arc.catch_pos.distance_to(proj_pos), 1.0)
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
