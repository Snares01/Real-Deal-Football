extends StateStanding
class_name StateShoved

static func shove(opp: Player, velocity: Vector2) -> StateShoved:
	var instance := StateShoved.new()
	instance.opp = opp
	instance.init_velocity = velocity
	return instance

const MIN_STUN_TIME := 0.2
const STUN_MULTIPLIER := 0.005
const MAX_STUN_TIME := 0.6

var opp: Player
var init_velocity: Vector2

func _init() -> void:
	anim_name = "shove"
	interrupting = true


func _ready() -> void:
	# determine time in stun
	var stun_time: float = min(MIN_STUN_TIME + (init_velocity.length() * STUN_MULTIPLIER), MAX_STUN_TIME)
	player.velocity = -player.velocity * stun_time
	#print("stun: " + str(stun_time))
	var timer := get_tree().create_timer(stun_time)
	timer.timeout.connect(_on_stun_finished)


func _process(delta: float) -> void:
	if opp.position.x < player.position.x:
		player.flip_sprite(true)
	else:
		player.flip_sprite(false)
	super._process(delta)


func _on_stun_finished() -> void:
	end_state()
