extends StateRunning
class_name StateRunningWithBall

const CAST_AHEAD := 10.0 # In pixels
const ANGLE_STEP := 5.0 # In degrees

const ANGLE_RATING_MULT := 1.0
const MAX_CHASER_DIST := 100.0 # Don't avoid chasers past this distance
const TICK_RATE := 0.1

var tick_timer := TICK_RATE


func _process(delta: float) -> void:
	# Don't update every frame to avoid changing directions too often & slowing down
	tick_timer -= delta
	if tick_timer < 0.0:
		tick_timer = TICK_RATE
		_update_target()
	#print("FRAME FINISHED")
	super._process(delta)


func _update_target() -> void:
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

# Distance of point pos to line between player.position and line_b
func _dist_to_line(pos: Vector2, line_b: Vector2) -> float:
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
