extends State
class_name StateCatching

const MAX_CATCH_TIME := 0.5 # Seconds until we give up on catching
const CATCH_HEIGHT := 15.0
const CATCH_THRESHOLD := 12.0 # How close the ball has to be for an instant catch

var prev_ball_dist: float
var time_left := MAX_CATCH_TIME

func _init() -> void:
	interrupting = true
	anim_name = "run_catch"


func _process(delta: float) -> void:
	if manager.ball == null:
		end_state()
		return
	
	var ball_dist := manager.ball.vec3_pos.distance_to(
		Vector3(player.position.x, player.position.y, CATCH_HEIGHT))
	# Catch if ball is close enough or getting farther away
	if time_left < 0.0:
		if ball_dist < player.CATCH_RANGE:
			_catch()
		else:
			end_state()
	elif ((ball_dist < CATCH_THRESHOLD) or
	 (prev_ball_dist and prev_ball_dist < ball_dist and ball_dist < player.CATCH_RANGE)):
		_catch()
	
	prev_ball_dist = ball_dist
	time_left -= delta


func _catch() -> void:
	if manager.ball.velocity.z > 0:
		return # Only catch ball traveling downwards
	if player.attempt_catch():
		player.set_state(StateRunningWithBall.new())
	else:
		end_state()
