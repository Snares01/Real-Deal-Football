extends StateRunning
class_name StateCovering

# Find coverage on ready (_get_assignment)
static func cover_role(role: Player.Role, line_dist: float) -> StateCovering:
	var instance := StateCovering.new()
	instance.role_to_cover = role
	instance.dist_from_line = line_dist
	return instance

# Assumed man is already assigned
static func cover_man(line_dist: float) -> StateCovering:
	var instance := StateCovering.new()
	instance.dist_from_line = line_dist
	return instance

@onready var react_time_left := stats.reaction_time # updates predict_direction

var predict_velocity := Vector2.ZERO # where we think our man is going
var role_to_cover: Player.Role
var dist_from_line: float
# Set in _ready()
var line_up: bool # Set to false on play start
var man: Player

func _ready() -> void:
	line_up = not Globals.is_play_active
	# Set man to cover if not already set
	if player.get_man() == null:
		player.set_man(_get_assignment(), PlayerGraph.Relation.COVERING)
	man = player.get_man()


func _process(delta: float) -> void:
	if man == null:
		end_state()
	else:
		if line_up:
			# Move to line up
			target_pos.y = man.global_position.y
			if Globals.drive_dir:
				target_pos.x = (Globals.scrimmage*Field.YARD) + dist_from_line
			else:
				target_pos.x = (Globals.scrimmage*Field.YARD) - dist_from_line
		else:
			# Cover target
			target_pos = man.position + (predict_velocity * stats.predict_dist)
			# Update prediction_direction
			react_time_left -= delta
			if react_time_left < 0.0:
				react_time_left = stats.reaction_time
				predict_velocity = man.velocity
	
	super._process(delta)

# Override
func on_target_reached() -> void:
	if man != null and (man.get_state() is StateSet or man.get_state() is StateStanding):
		player.set_state(StateCoveringSet.covering(dist_from_line))

# Override
func handle_event(event: Event) -> void:
	if event == Event.PLAY_START:
		line_up = false
	super.handle_event(event)


func _get_assignment() -> Player: # Can return null
	var relations: Dictionary[Player, Array] = manager.graph.get_all_relations()
	# get player with least coverage
	var least_covered: Player = null
	var lowest_num := 99
	for p: Player in relations.keys():
		if (p.role == role_to_cover and p.on_home_team != player.on_home_team):
			var cover_num := 0
			# Count num of players covering
			for relation: PlayerGraph.Relation in relations[p]:
				if relation == PlayerGraph.Relation.COVERED:
					cover_num += 1
			
			if cover_num < lowest_num:
				lowest_num = cover_num
				least_covered = p
	
	return least_covered 
