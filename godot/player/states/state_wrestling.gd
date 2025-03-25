extends State
class_name StateWrestling

static func wrestle(player: Player) -> StateWrestling:
	var instance := StateWrestling.new()
	instance.opp = player
	return instance

const MIN_TICK_RATE := 0.1
const MAX_TICK_RATE := 0.5
const TACKLE_TIME := 0.66
const BASE_SHOVE_FORCE := 30.0
const MAX_DISTANCE := 16.0
const BASE_SHOVE_CHANCE := 0.15
const BASE_TACKLE_CHANCE := 0.05

var opp: Player
var push_dir: Vector2
var tick_rate := randf_range(MIN_TICK_RATE, MAX_TICK_RATE)
var time_left := tick_rate
# set in _ready
var shove_chance: float
var tackle_chance: float
var shove_force: float # force when shoving player & exiting wrestle
var push_force: float # force when moving forward

func _init() -> void:
	interrupting = true
	anim_name = "wrestle"


func _ready() -> void:
	push_dir = player.velocity.normalized()
	player.velocity = Vector2.ZERO
	var ratio := stats.strength / opp.stats.weight
	shove_chance = BASE_SHOVE_CHANCE * ratio
	tackle_chance = BASE_TACKLE_CHANCE * ratio
	shove_force = BASE_SHOVE_FORCE * (stats.strength / 100.0)
	push_force = stats.strength / 100.0


func _process(delta: float) -> void:
	if opp.position.x < player.position.x:
		player.flip_sprite(true)
	else:
		player.flip_sprite(false)
	if not opp.get_state() is StateWrestling:
		end_state()
	# tick rate
	time_left -= delta
	if time_left < 0.0:
		time_left = tick_rate
		tick()
	# stay close to each other
	if opp.position.distance_to(player.position) > MAX_DISTANCE:
		var dir := player.position.direction_to(opp.position)
		player.position += dir * player.PUSH_FORCE * delta


func tick() -> void:
	var rand := randf()
	if rand < tackle_chance:
		opp.set_state(StateTackled.tackle(TACKLE_TIME, push_dir * shove_force))
		end_state()
	elif rand < shove_chance + tackle_chance:
		opp.set_state(StateShoved.shove(player, push_dir * shove_force))
		end_state()
	else: # push
		player.position += push_dir * push_force
