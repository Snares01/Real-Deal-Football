extends State
class_name StateTackled

static func tackle(time: float, velocity: Vector2) -> StateTackled:
	var instance := StateTackled.new()
	instance.time_left = time
	instance.init_velocity = velocity
	return instance

const FRICTION := 80.0

var time_left: float
var init_velocity: Vector2


func _init() -> void:
	interrupting = true
	anim_name = "tackled"


func _ready() -> void:
	player.velocity = init_velocity
	get_tree().create_timer(time_left).timeout.connect(_on_tackle_finished)
	# Face towards tackler, getting hit backwards
	player.flip_sprite(init_velocity.x > 0)
	
	if manager.ball_carrier == player:
		SignalBus.game_event.emit(State.Event.BALL_CARRIER_TACKLED)


func _process(delta: float) -> void:
	# Slow down
	if player.velocity.length() > 0.0:
		player.velocity = (player.velocity.normalized()
		 * move_toward(player.velocity.length(), 0, delta * FRICTION))


func _on_tackle_finished() -> void:
	player.set_state(StateGettingUp.new())
