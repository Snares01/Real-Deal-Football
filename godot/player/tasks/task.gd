extends Resource
class_name Task
# Resource that creates state(s) that accomplish specific task
# Used in PlayCalls

@export var role: Player.Role
@export var line_up: Vector2

# Overridden by subtype states
func get_state() -> State:
	return StateStanding.new()

# Called by player_graph to line players up
func get_line_up(offense: bool) -> State:
	var line_pos := Vector2(Globals.scrimmage * Field.YARD, line_up.y)
	if (Globals.drive_dir and offense) or (not Globals.drive_dir and not offense):
		line_pos.x += line_up.x
	else:
		line_pos.x -= line_up.x
	
	var state := StateRunning.towards(line_pos)
	state.next = StateSet.new()
	state.next.next = get_state()
	return state
