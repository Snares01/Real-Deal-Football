extends StateRunning
class_name StateChasing
# Run after player for tackle

static func chase_role(role: Player.Role) -> StateChasing:
	var instance := StateChasing.new()
	instance.role_to_chase = role
	return instance

static func chase_man(man: Player) -> StateChasing:
	var instance := StateChasing.new()
	instance.man_to_chase = man
	return instance

@onready var react_time_left := stats.reaction_time # updates predict_direction

var role_to_chase: Player.Role
var man_to_chase: Player

var predict_velocity := Vector2.ZERO # where we think our man is going
var man: Player

func _init() -> void:
	target_reached_margin = 21.0
	super._init()


func _ready() -> void:
	if man_to_chase:
		player.set_man(man_to_chase, PlayerGraph.Relation.CHASING)
	else: # role to chase
		player.set_man(_get_assignment(), PlayerGraph.Relation.CHASING)
	man = player.get_man()


func _process(delta: float) -> void:
	var man := player.get_man()
	if man == null:
		end_state()
	else:
		target_pos = player.get_player_interception_pos(man)
		#target_pos = player.get_interception_pos(man.position, predict_velocity)
		# Update prediction_direction
		react_time_left -= delta
		if react_time_left < 0.0:
			react_time_left = stats.reaction_time
			predict_velocity = man.velocity
	
	super._process(delta)

# Override
func on_target_reached() -> void:
	# TODO: make this function empty, transition to StateTackling when close in _process
	if player.position.distance_to(player.get_man().position) < target_reached_margin:
		player.get_man().set_state(StateTackled.tackle(1.0, player.velocity))
		end_state()


func _get_assignment() -> Player: # Can return null
	var relations: Dictionary[Player, Array] = manager.graph.get_all_relations()
	# get player with least coverage
	var least_covered: Player = null
	var lowest_num := 99
	for p: Player in relations.keys():
		if (p.role == role_to_chase and p.on_home_team != player.on_home_team):
			var cover_num := 0
			# Count num of players covering
			for relation: PlayerGraph.Relation in relations[p]:
				if relation == PlayerGraph.Relation.COVERED:
					cover_num += 1
			
			if cover_num < lowest_num:
				lowest_num = cover_num
				least_covered = p
	
	return least_covered 
