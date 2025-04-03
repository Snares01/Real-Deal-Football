extends StateRunning
class_name StateRunningWithBall

const CAST_AHEAD := 10.0 # In pixels
const ANGLE_STEP := 5.0 # In degrees

const ANGLE_RATING_MULT := 1.0
const MAX_CHASER_DIST := 100.0 # Don't avoid chasers past this distance
const TICK_RATE := 0.66

var tick_timer := TICK_RATE

func _ready() -> void:
	_update_target()


func _process(delta: float) -> void:
	# Don't update every frame to avoid changing directions too often & slowing down
	tick_timer -= delta
	if tick_timer < 0.0:
		tick_timer = TICK_RATE
		_update_target()
	
	super._process(delta)

var angry := true
func _update_target() -> void:
	var chasers := manager.graph.get_player_relations(player, PlayerGraph.Relation.CHASING)
	# x = angle (deg), y = time to tackle, z = forward progress at tackle
	var angle_options: Array[Vector3]
	var num_blocked := 0
	# Populate angle_options by testing a range of angles
	for ang_deg: float in range(-85, 90, ANGLE_STEP):
		var ang_rad := deg_to_rad(ang_deg)
		var ang_vel := Vector2.from_angle(ang_rad) * stats.sprint_speed
		# Going out of bounds
		if abs((player.position + ang_vel).y) > (Field.HEIGHT - 1) * Field.YARD / 2.0:
			continue
		
		var time_till_tackled := INF
		var forward_progress := INF
		# See how long it will take chasers to get to us 
		for chaser in chasers:
			var time_to_tackle := chaser.get_intercept_time(player.position, ang_vel)
			# Chaser can't get to us
			if time_to_tackle < 0.0:
				continue
			
			# Add time depending on chaser's state
			var bonus_time := 0.0
			var c_state := chaser.get_state()
			if c_state is StateTackled or c_state is StateWrestling:
				bonus_time += 1.0
			elif c_state is StateShoved:
				bonus_time += 0.25 # 
			# Add bonus time if a blocker is between us & chaser
			var blockers := manager.graph.get_player_relations(chaser, PlayerGraph.Relation.BLOCKING)
			var is_blocked := false
			for blocker in blockers:
				# If blocker is closer & in about the same direction from us
				if (blocker.position.distance_squared_to(player.position)
				 < chaser.position.distance_squared_to(player.position) / 2.0
				 and player.position.direction_to(chaser.position).dot(
				 player.position.direction_to(blocker.position)) > 0.6):
					is_blocked = true
					break
			if is_blocked:
				bonus_time += 2.0
			if bonus_time > 0.0:
				num_blocked += 1
			# See if we will pass them while they are being tackled or whatever
			var progress_at_bonus := player.position.x + (ang_vel.x * bonus_time)
			if bonus_time > 0.0 and progress_at_bonus > chaser.position.x:
				continue
			time_to_tackle += bonus_time
			# Get shortest time to tackle & forward progress at tackle
			if time_to_tackle < time_till_tackled:
				time_till_tackled = time_to_tackle
				forward_progress = ang_vel.x * time_to_tackle
		# Save option to list
		angle_options.append(Vector3(ang_deg, time_till_tackled, forward_progress))
	
	# Get best angles out of angle_options
	var longest_time := 0.0
	var longest_time_ang := 0.0
	var most_progress := 0.0
	var most_progress_ang := 0.0
	for ang_info in angle_options:
		print(ang_info)
		var angle_deg := ang_info.x
		var time_till_tackle := ang_info.y # INF if no one can tackle us
		var forward_progress := ang_info.z # INF if no one can tackle us
		# TODO: Add to forward progress if angle is facing forward
		
		
		if forward_progress > most_progress:
			most_progress = forward_progress
			most_progress_ang = angle_deg
		if time_till_tackle > longest_time:
			longest_time = time_till_tackle
			longest_time_ang = angle_deg
	# Choose position to run in
	# TODO: Make everything in this if statement dependent on anger stat
	# num_blocked is mostly to encourage running through the linemen
	# If we are about to be tackled really soon or not soon at all, prefer immediate forward progress
	if num_blocked > 5 or longest_time < TICK_RATE or longest_time > TICK_RATE * 2:
		print("most progress: " + str(most_progress_ang))
		target_pos = player.position + (Vector2.from_angle(deg_to_rad(most_progress_ang)) * stats.sprint_speed)
	else:
		print("hi")
		print(longest_time)
		print(TICK_RATE)
		print("huh")
		print("tackle not soon " + str(longest_time_ang))
		var ang := deg_to_rad((longest_time_ang + most_progress_ang) / 2.0)
		target_pos = player.position + (Vector2.from_angle(ang) * stats.sprint_speed)


func _OLD_update_target() -> void:
	var chasers := manager.graph.get_player_relations(player, PlayerGraph.Relation.CHASING)
	# Look ahead at different angles, get best run target based on rating
	# Get rating based on forward progress & distance to chasers / blockers
	var highest_rating := -INF
	for ang_deg: float in range(-90, 95, ANGLE_STEP):
		var ang_rad := deg_to_rad(ang_deg)
		var look_ahead := player.position + (Vector2.from_angle(ang_rad) * CAST_AHEAD)
		var rating := 0.0
		# Don't go out of bounds 
		if abs(look_ahead.y) > (Field.HEIGHT - 1) * Field.YARD / 2.0:
			continue
		# Decrease rating the farther from forward progress (0) it is
		var angle_rating: float = abs(ang_deg) * -ANGLE_RATING_MULT
		# Decrease rating the closer to a chaser it is
		var chaser_rating := -MAX_CHASER_DIST
		for chaser in chasers:
			if not chaser.get_state() is StateChasing:
				continue
			var new_rating := -MAX_CHASER_DIST + _dist_to_line(chaser.position + chaser.velocity, look_ahead)
			if new_rating < 0.0:
				chaser_rating += new_rating
		
		rating += angle_rating
		rating += chaser_rating
		if rating > highest_rating:
			#print("ang: " + str(angle_rating))
			#print("chase: " + str(chaser_rating))
			highest_rating = rating
			target_pos = look_ahead

# Distance of point "pos" to line between player.position and line_b
func _dist_to_line(pos: Vector2, line_b: Vector2) -> float:
	# shoutouts wikipedia
	var line_a := player.position
	var numerator: float = abs((line_b.y - line_a.y)*pos.x - (line_b.x - line_a.x)*pos.y
	 + line_b.x*line_a.y - line_b.y*line_a.x)
	var denominator := sqrt(pow(line_b.y - line_a.y, 2) + pow(line_b.x - line_a.x, 2))
	if denominator == 0.0:
		return 0.0
	return numerator / denominator

# Override
func on_target_reached() -> void:
	pass
