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
