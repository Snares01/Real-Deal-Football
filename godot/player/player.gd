extends Area2D
class_name Player

enum Role {
	QB,
	WR,
	DB,
	DT,
	DE,
	OG,
	OT,
	C,
}

const PUSH_FORCE := 10.0 # Keeps players from occupying same space
# Make these consts player stats
const DEFLECT_RANGE := 15.0
const MAX_DEFLECT_CHANCE := 0.8
const CATCH_RANGE := 25.0
const CATCH_CHANCE := 0.9

@onready var stats := PlayerStats.new_default(role)
@onready var manager: PlayerManager = get_parent()
@onready var animator: AnimationPlayer = $Animator
@onready var spr_bottom: Sprite2D = $Bottom
@onready var spr_top: Sprite2D = $Top

var _current_state: State
var _previous_state: State # Used during interrupting states
var role: Role
var on_home_team: bool
# V Used by states V
var velocity := Vector2.ZERO
var zone: Rect2
var _man: Player = null # Man being covered / targeted (set through set_man())


func _ready() -> void:
	SignalBus.game_event.connect(trigger_event)
	set_state(StateStanding.new())
	if on_home_team:
		modulate = Color(1, 0.5, 0.5)
	else:
		modulate = Color(0.5, 0.5, 1)


func _process(delta: float) -> void:
	position += velocity * delta
	if _current_state == null:
		print("player.gd: CURRENT STATE NOT FOUND prev state: " + _previous_state.get_script().get_global_name())
		return
	# Push away from close players
	if not (_current_state is StateSet or _current_state is StateTackled):
		for player in get_overlapping_areas():
			if not player is Player:
				return
			var dir := position.direction_to(player.position) * -1.0
			position += dir * PUSH_FORCE * delta
	# check if out of bounds / in endzone
	if Globals.is_play_active and manager.ball_carrier == self:
		if is_out_of_bounds():
			SignalBus.game_event.emit(State.Event.OUT_OF_BOUNDS)
		elif ((on_home_team and position.x > 50.0 * Field.YARD)
		 or not on_home_team and position.x < -50.0 * Field.YARD):
			SignalBus.game_event.emit(State.Event.TOUCHDOWN)
	#$Debug.text = _current_state.get_script().get_global_name()


func is_out_of_bounds() -> bool:
	return ((abs(position.y) > Field.HEIGHT * Field.YARD / 2.0
	 or abs(position.x) > (100 + Field.ENDZONE_WIDTH*2) * Field.YARD / 2.0))


func set_state(state: State) -> void:
	# remove current state
	if _current_state:
		remove_child(_current_state)
		if state.interrupting and not _current_state.interrupting:
			_previous_state = _current_state
			_current_state.on_interruption()
		else:
			_current_state.queue_free()
	# add state
	_current_state = state
	state.player = self
	state.manager = manager
	add_child(state)
	# update animation
	if animator.current_animation.is_empty():
		if manager.ball_carrier == self and not state.ball_anim_name.is_empty():
			animator.play(state.ball_anim_name)
		else:
			animator.play(state.anim_name)
	else: # Keep anim position for smooth transitions (if lengths are the same)
		var prev_length := animator.current_animation_length
		var prev_pos := animator.current_animation_position
		# change anim
		if manager.ball_carrier == self and not state.ball_anim_name.is_empty():
			animator.play(state.ball_anim_name)
		else:
			animator.play(state.anim_name)
		
		if animator.current_animation_length == prev_length:
			animator.seek(prev_pos)
	
	if not _current_state:
		print("player.gd: set_state went wrong. horribly wrong")
		continue_previous_state()


func continue_previous_state() -> void:
	if _previous_state:
		set_state(_previous_state)
	else:
		print("player.gd: previous state not found. current_state: " + _current_state.get_script().get_global_name())
		set_state(StateStanding.new())


func get_state() -> State:
	return _current_state


func set_man(new_man: Player = null, relation := PlayerGraph.Relation.NONE) -> void:
	if _man != null:
		manager.graph.remove_relation(_man, self)
	_man = new_man
	if new_man != null:
		manager.graph.add_relation(_man, self, relation)


func get_man() -> Player:
	return _man


func flip_sprite(flipped: bool) -> void:
	spr_bottom.flip_h = flipped
	spr_top.flip_h = flipped

# Assumes ball is midair
func attempt_catch() -> bool:
	if manager.ball == null or manager.ball.is_catchable == false:
		return false
	var dist_to_ball := manager.ball.dist_to(self)
	# Get list of players that are covering this player & in pass deflect state
	# For each player, roll chance that pass gets deflected
	var p_covering := manager.graph.get_player_relations(self, PlayerGraph.Relation.COVERING)
	for player in p_covering:
		if player.get_state() is StatePassDeflecting:
			# Roll chance that pass is deflected
			var rand := randf()
			# Dist to ball or dist to player, whichever is better
			var db_dist: float = min(manager.ball.dist_to(player), position.distance_to(player.position))
			var deflect_chance: float = min(1 - (db_dist / DEFLECT_RANGE), MAX_DEFLECT_CHANCE)
			print("player.gd: deflect chance: " + str(deflect_chance))
			if rand < deflect_chance:
				manager.ball.deflect(player)
				return false
	# Roll dice to see if ball is caught
	var rand := randf()
	if rand > CATCH_CHANCE:
		print("missed catch")
		return false
	# update animation
	if not _current_state.ball_anim_name.is_empty():
		animator.play(_current_state.ball_anim_name)
	# update player manager
	if manager.ball != null:
		manager.ball_carrier = self
		manager.ball.queue_free()
		manager.ball = null
	# send signal
	if is_out_of_bounds():
		SignalBus.game_event.emit(State.Event.INCOMPLETION)
	else:
		SignalBus.game_event.emit(State.Event.BALL_CAUGHT)
	return true

# Used for player-specific events (ie ball nearby)
func trigger_event(event: State.Event) -> void:
	_current_state.handle_event(event)
	# Clear vars
	if event == State.Event.PLAY_END:
		_previous_state = null
		zone = Rect2(0, 0, 0, 0)
		set_man(null)

# Returns position to run towards to inercept target's path
# Returns target's position if we can't get there
func get_player_interception_pos(target: Player) -> Vector2:
	if target.velocity.is_zero_approx():
		return target.position # Assume target will continue standing still
	# Solve for case where both are at constant velocity (max_speed)
	var intercept_time := get_player_intercept_time(target)
	if intercept_time <= 0.0:
		return target.position
	# TODO: Approximate more accurate position by accounting for acceleration
	# get position target will be in
	var target_pos := target.position + (target.velocity.normalized() * stats.sprint_speed * intercept_time)
	return target_pos

# Same as get_player_interception_pos
func get_interception_pos(target_pos: Vector2, target_vel: Vector2) -> Vector2:
	if target_vel.is_zero_approx():
		return target_pos
	# Solve for case where both are at constant velocity (max_speed)
	var intercept_time := get_intercept_time(target_pos, target_vel)
	if intercept_time <= 0.0:
		return target_pos
	# get position target will be in
	var output := target_pos + (target_vel.normalized() * stats.sprint_speed * intercept_time)
	return output


# Get time to intercept other player, assuming both players are at max speed (bc fuck math)
# Returns -1.0 if player can't be reached
func get_player_intercept_time(target: Player) -> float:
	var to_target := target.position - position
	var target_vel := target.velocity.normalized() * target.stats.sprint_speed
	# get coefficents
	var a: float = target_vel.dot(target_vel) - (stats.sprint_speed * stats.sprint_speed)
	var b: float = 2.0 * target_vel.dot(to_target)
	var c: float = to_target.dot(to_target)
	# solve for time linearly if a is close to zero
	if abs(a) < 0.001:
		# Solve using linear equation
		if abs(b) < 0.001:
			return -1.0
		elif -c / b > 0:
			return -c / b
		else:
			return -1.0
	# get discriminant
	var discriminant := (b * b) - (4.0 * a * c)
	if discriminant < 0:
		return -1.0
	# solve for time quadratically
	var t1 := (-b + sqrt(discriminant)) / (2.0 * a)
	var t2 := (-b - sqrt(discriminant)) / (2.0 * a)
	# get smallest time that's positive
	if min(t1, t2) > 0.0:
		return min(t1, t2)
	elif max(t1, t2) > 0.0:
		return max(t1, t2)
	return -1.0

# Same as get_player_intercept_time but with different arguments
func get_intercept_time(target_pos: Vector2, target_vel: Vector2) -> float:
	var to_target := target_pos - position
	# get coefficents
	var a: float = target_vel.dot(target_vel) - (stats.sprint_speed * stats.sprint_speed)
	var b: float = 2.0 * target_vel.dot(to_target)
	var c: float = to_target.dot(to_target)
	# solve for time linearly if a is close to zero
	if abs(a) < 0.001:
		# Solve using linear equation
		if abs(b) < 0.001:
			return -1.0
		elif -c / b > 0:
			return -c / b
		else:
			return -1.0
	# get discriminant
	var discriminant := (b * b) - (4.0 * a * c)
	if discriminant < 0:
		return -1.0
	# solve for time quadratically
	var t1 := (-b + sqrt(discriminant)) / (2.0 * a)
	var t2 := (-b - sqrt(discriminant)) / (2.0 * a)
	# get smallest time that's positive
	if min(t1, t2) > 0.0:
		return min(t1, t2)
	elif max(t1, t2) > 0.0:
		return max(t1, t2)
	return -1.0
