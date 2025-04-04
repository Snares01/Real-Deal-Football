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
	player.get_node("Debug").text = str(int(stats.anger * 100.0))


func _process(delta: float) -> void:
	# Don't update every frame to avoid changing directions too often & slowing down
	tick_timer -= delta
	if tick_timer < 0.0:
		tick_timer = TICK_RATE
		_update_target()
	
	super._process(delta)


func _update_target() -> void:
	var upper_bound := (Field.HEIGHT * Field.YARD / 2.0)
	var chasers := manager.graph.get_player_relations(player, PlayerGraph.Relation.CHASING)
	
	var angle_options: Array[AngleInfo]
	var num_blocked := 0
	var ang_range: Array
	if player.on_home_team:
		ang_range = range(-100, 95, ANGLE_STEP)
	else:
		ang_range = range(80, 275, ANGLE_STEP)
	# Populate angle_options by testing a range of angles
	for ang_deg: float in ang_range:
		var ang_rad := deg_to_rad(ang_deg)
		var ang_vel := Vector2.from_angle(ang_rad) * stats.sprint_speed
		
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
			var future_pos := player.position + ang_vel
			var blockers := manager.graph.get_player_relations(chaser, PlayerGraph.Relation.BLOCKING)
			var is_blocked := false
			for blocker in blockers:
				# If blocker is closer & in about the same direction from us
				if (blocker.position.distance_squared_to(future_pos)
				 < chaser.position.distance_squared_to(future_pos) / 2.0
				 and future_pos.direction_to(chaser.position).dot(
				 future_pos.direction_to(blocker.position)) > 0.8):
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
		
		# Count going out of bounds as moment of tackle
		if ang_vel.y != 0.0:
			# Find time until we go out of bounds
			var t_out_of_bounds := 0.0
			if ang_vel.y > 0.0:
				t_out_of_bounds = (upper_bound - player.position.y) / ang_vel.y
			elif ang_vel.y < 0.0:
				t_out_of_bounds = (-upper_bound - player.position.y) / ang_vel.y
			# Overwrite time until tackled if we will go out of bounds first
			if time_till_tackled > t_out_of_bounds:
				time_till_tackled = t_out_of_bounds
				forward_progress = ang_vel.x * t_out_of_bounds
		# Save option to list
		if not player.on_home_team:
			forward_progress *= -1.0
		angle_options.append(AngleInfo.make(ang_rad, time_till_tackled, forward_progress, num_blocked, stats.anger))
	
	# Get best angle given anger stat
	var top_angle: AngleInfo = angle_options[0] # Best overall
	for ang_info in angle_options:
		if ang_info.rating > top_angle.rating:
			top_angle = ang_info
	target_pos = player.position + (Vector2.from_angle(top_angle.ang) * stats.sprint_speed)


# Contains info for checked angles for _update_target
class AngleInfo:
	static func make(ang: float, t_tackle: float, prog: float, blockers: int, anger: float) -> AngleInfo:
		var info := AngleInfo.new()
		info.ang = ang
		info.t_tackle = t_tackle
		info.progress = prog
		info.num_blockers = blockers
		info.rating = info.get_rating(anger)
		return info
	
	const BLOCKER_MULT := 0.5 # How important num_blockers is for rating
	
	var ang: float # radians
	var t_tackle: float # time before tackle happens
	var progress: float # forward progress made at tackle
	var num_blockers: int
	var rating: float
	
	func get_rating(anger: float) -> float:
		var rating := (t_tackle * (1.0 - anger)) + (progress * (1.0 + anger))
		# Increase rating if blockers increase
		rating += (num_blockers * anger) * BLOCKER_MULT
		# TODO: Increase rating the closer to forward progress (0) it is
		return rating
	





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
