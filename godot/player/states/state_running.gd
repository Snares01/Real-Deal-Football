extends State
class_name StateRunning

const STANDING_TURN_SPEED := 999.0 # Should be infinite but really big number will suffice
# Turn these consts into stats
const DECEL := 140.0
const TURN_SPEED := 10.0 # Turn speed at MAX_SPEED

var target_pos: Vector2
var target_reached_margin := 3.0 # Pixels within target to call on_target_reached

static func towards(target_pos: Vector2) -> StateRunning:
	var instance = StateRunning.new()
	instance.target_pos = target_pos
	
	if target_pos != Vector2.ZERO:
		instance.target_pos = target_pos
	else:
		instance.target_pos = Vector2.UP
	return instance


func _init() -> void:
	anim_name = "run"
	ball_anim_name = "run_ball"


func _process(delta: float) -> void:
	if player.velocity == Vector2.ZERO:
		player.velocity = player.position.direction_to(target_pos)
	else:
		# Set max turn_speed
		var turn_speed = _get_turn_speed() * delta
		# Turn towards target direction
		var target_direction: Vector2 = (target_pos - player.position).normalized()
		var needed_turn: float = player.velocity.angle_to(target_direction)
		needed_turn = clamp(needed_turn, -turn_speed, turn_speed)
		# Set recommended speed, accel / decel
		var target_speed := _get_target_speed(target_direction)
		var speed: float
		if player.velocity.length() < target_speed:
			if player.velocity.length() < stats.run_speed:
				speed = min(stats.sprint_speed, player.velocity.length() + (stats.run_accel * delta))
			else:
				speed = min(stats.sprint_speed, player.velocity.length() + (stats.sprint_accel * delta))
		else:
			speed = max(0.0, player.velocity.length() - (DECEL * delta))
		# Apply turn & speed to velocity
		if player.velocity.length() < target_speed * 2.0:
			player.velocity = player.velocity.rotated(needed_turn)
		else:
			# Don't rotate if we need to slow down a lot (target_pos is behind us)
			speed = max(0.0, speed - (DECEL * delta))
		player.velocity = player.velocity.normalized() * speed
	
	#player.velocity = player.position.direction_to(target_pos) * speed
	# Reach target
	if player.position.distance_to(target_pos) < target_reached_margin:
		on_target_reached()
	# animation
	var spr_flip: bool = player.velocity.x < 0
	player.flip_sprite(spr_flip)

# Overriden in subclasses
func on_target_reached() -> void:
	end_state()

# Get max turn speed given velocity
func _get_turn_speed() -> float:
	# TURN_SPEED at MAX_SPEED, STANDING_TURN_SPEED at 0 speed
	var current_speed := 1.0 - (player.velocity.length() / stats.sprint_speed) # 0 at max speed, 1 at stand-still
	var turn_speed := ((current_speed * (STANDING_TURN_SPEED - TURN_SPEED)) / stats.sprint_speed) + TURN_SPEED
	return turn_speed

# Get speed we should be moving at
# (If target pos is behind us, decelerate before turning)
func _get_target_speed(target_dir: Vector2) -> float:
	var angle_diff := (player.velocity.normalized().dot(target_dir) / 2.0) + 0.5 #0-1
	var target_speed: float = max(1.0, angle_diff * stats.sprint_speed)
	# Don't let target_speed actually go to zero
	return target_speed

# Returns position after running route for given duration
func calculate_route_pos(time: float) -> Vector2:
	var travel_dist := calculate_route_distance(time)
	var new_pos := player.position.move_toward(target_pos, travel_dist)
	
	var dist_to_target := player.position.distance_to(target_pos)
	if dist_to_target < travel_dist:
		travel_dist -= dist_to_target
		if next != null and next is StateRunning:
			# Reaches new target in route
			new_pos = new_pos.move_toward(next.target_pos, travel_dist)
	#print(player.position - new_pos)
	return new_pos


const TURN_DIST_PENALTY := 50.0
const END_ROUTE_MARGIN := 30.0
func calculate_route_distance(time: float) -> float:
	var travel_dist := _calculate_distance(time)
	# reduce distance the more target_pos is in a different direction
	var ang_diff := 1.0 - ((player.velocity.normalized()
		.dot(player.position.direction_to(target_pos)) + 1.0) / 2.0)
	travel_dist = max(0.0, travel_dist - (TURN_DIST_PENALTY * ang_diff))
	#print(travel_dist)
	# Determine if we will reach target_pos
	var target_pos_dist := player.position.distance_to(target_pos)
	if (target_pos_dist < travel_dist):
		# See if there is another point in route
		if next != null and next is StateRunning:
			var next_target_pos_dist := target_pos.distance_to(next.target_pos)
			# Reduce distance the more next.target_pos is in different direction
			ang_diff = 1.0 - ((player.position.direction_to(target_pos)
				.dot(target_pos.direction_to(next.target_pos)) + 1.0) / 2.0)
			travel_dist = clamp(travel_dist - (TURN_DIST_PENALTY * ang_diff), target_pos_dist, target_pos_dist + next_target_pos_dist)
		else:
			# Cap distance to end of route
			travel_dist = min(target_pos_dist, travel_dist)
	# Reduce distance the more next target_pos is in different direction
	print(travel_dist)
	return travel_dist

# Get distance travelled in given time (assuming acceleration)
func _calculate_distance(time: float) -> float:
	var distance := 0.0
	var current_speed := player.velocity.length()
	var time_left := time
	
	# At full sprint
	if is_equal_approx(current_speed, stats.sprint_speed):
		return current_speed * time
	# Above run speed
	elif current_speed >= stats.run_speed:
		var t_to_sprint_speed := (stats.sprint_speed - current_speed) / stats.sprint_accel
		
		if time_left <= t_to_sprint_speed:
			#print("A")
			# Won't reach sprint speed
			distance = (current_speed * time_left) + (0.5 * stats.sprint_accel * time_left * time_left)
		else:
			#print("B")
			# Will reach sprint speed
			distance = (current_speed * time_left) + (0.5 * stats.sprint_accel * t_to_sprint_speed * t_to_sprint_speed)
			time_left -= t_to_sprint_speed
			distance += stats.sprint_speed * time_left
	# Below run speed
	else:
		var t_to_run_speed := (stats.run_speed - current_speed) / stats.run_accel
		
		if time_left <= t_to_run_speed:
			#print("C")
			# Won't reach run speed
			distance = (current_speed * time_left) + (0.5 * stats.run_accel * time_left * time_left)
		else:
			# Will reach run speed
			distance = (current_speed * time_left) + (0.5 * stats.run_accel * t_to_run_speed * t_to_run_speed)
			time_left -= t_to_run_speed
			# Check if we will reach sprint speed
			var t_to_sprint_speed := (stats.sprint_speed - current_speed) / stats.sprint_accel
			if time_left <= t_to_sprint_speed:
				#print("D")
				# Won't reach sprint speed
				distance += (current_speed * time_left) + (0.5 * stats.sprint_accel * time_left * time_left)
			else:
				#print("E")
				# Will reach sprint speed
				distance += (current_speed * time_left) + (0.5 * stats.sprint_accel * t_to_sprint_speed * t_to_sprint_speed)
				time_left -= t_to_sprint_speed
				distance += stats.sprint_speed * time_left
	#print(distance)
	return distance
