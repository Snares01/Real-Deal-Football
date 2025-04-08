extends Area2D
class_name Ball

const CATCH_HEIGHT := 15.0
const THROW_SENSITIVITY := 0.1
const THROW_HEIGHT_GAIN := 22.0
const THROW_POWER := 30.0
const THROW_START_HEIGHT := 20.0
const THROW_ARC_TICKRATE := 0.05
const GRAVITY := 210.0
const AIR_FRICTION := 0 #50.0

@onready var sprite: Sprite2D = $Sprite

var is_catchable := true
# set on creation
var velocity: Vector3
var vec3_pos: Vector3
var initial_velocity: float

# Used for aiming visual
static func get_arc_points(throw_input: Vector2) -> Array[Vector3]:
	var output: Array[Vector3] = []
	var aim_vel := swipe_to_velocity(throw_input)
	var initial_vel := aim_vel.length()
	var ball_pos := Vector3(0, 0, THROW_START_HEIGHT)
	
	while ball_pos.z > 0:
		output.append(ball_pos)
		ball_pos += aim_vel * THROW_ARC_TICKRATE
		aim_vel.z -= GRAVITY * THROW_ARC_TICKRATE
		aim_vel = aim_vel.limit_length(aim_vel.length() - (AIR_FRICTION * THROW_ARC_TICKRATE))
	return output


static func swipe_to_velocity(throw_input: Vector2) -> Vector3:
	# Commented-out code calculates THROW_ANGLE
	var output := Vector3(throw_input.x, throw_input.y, 0)
	output *= THROW_SENSITIVITY * THROW_POWER
	#var horizontal := output.length()
	output.z = throw_input.length() * THROW_SENSITIVITY * THROW_HEIGHT_GAIN
	#var angle := Vector2(horizontal, output.z)
	#print(angle.angle())
	return output

const THROW_ANGLE := 0.633 # in radians above ground
static func time_to_target(start_pos: Vector2, target_pos: Vector2) -> float:
	# TODO: Maybe add some margin to throw_dist
	var throw_dist := start_pos.distance_to(target_pos)
	# What is known: distance, launch angle, gravity, friction
	var velocity := sqrt((GRAVITY * throw_dist) / (2.0 * cos(THROW_ANGLE) * sin(THROW_ANGLE)))
	return throw_dist / velocity


func _ready() -> void:
	area_entered.connect(_on_player_entered)
	initial_velocity = velocity.length()


func _process(delta: float) -> void:
	var prev_pos := global_position
	# movement
	vec3_pos += velocity * delta
	velocity.z -= GRAVITY * delta
	global_position = Vector2(vec3_pos.x, vec3_pos.y)
	# air friction
	velocity = velocity.limit_length(velocity.length() - (AIR_FRICTION * delta))
	# floor bounce
	if vec3_pos.z < 0 and velocity.z < 0:
		is_catchable = false
		if Globals.is_play_active:
			get_tree().create_timer(1.0).timeout.connect(_on_incomplete_timeout)
			SignalBus.game_event.emit(State.Event.INCOMPLETION)
		velocity *= 0.5
		velocity.z *= -1
	# visuals
	sprite.position.y = -vec3_pos.z
	if vec3_pos.z > 5:
		sprite.z_index = 5
	else:
		sprite.z_index = 0
	queue_redraw()


func _on_player_entered(player: Player) -> void:
	if player == null:
		print("ball.gd: non-player on player collision layer")
		return
	player.trigger_event(State.Event.BALL_NEARBY)


func deflect(from: Player) -> void:
	var deflect_dir := position.direction_to(from.position) * -1
	var deflect_vel := velocity.length() / 3.0
	velocity.x = deflect_dir.x * deflect_vel
	velocity.y = deflect_dir.y * deflect_vel
	velocity.z = randf_range(5.0, -10.0)
	# Make temporarily uncatchable
	is_catchable = false
	get_tree().create_timer(0.2).timeout.connect(_on_inactive_period_end)


func dist_to(player: Player) -> float:
	var player_pos := Vector3(player.position.x, player.position.y, CATCH_HEIGHT)
	return player_pos.distance_to(vec3_pos)

# Delete ball after incompletion
func _on_incomplete_timeout() -> void:
	queue_free()

# For making ball temporarily uncatchable after deflection / fumble
func _on_inactive_period_end() -> void:
	if Globals.is_play_active:
		is_catchable = true

func _draw() -> void:
	# shadow
	draw_circle(Vector2.ZERO, 2, Color(0, 0, 0, 0.3))
