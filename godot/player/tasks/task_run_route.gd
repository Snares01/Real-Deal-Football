extends Task
class_name TaskRunRoute

@export var route: Array[Vector2]

func get_state() -> State:
	if route.is_empty():
		return StateStanding.new()
	# create running state for each position in route
	var state_list: StateRunning = null
	for pos in route:
		# get local position
		var local_pos := Vector2((Globals.scrimmage * Field.YARD), pos.y)
		if Globals.drive_dir: # assume we're on offense
			local_pos += Vector2(line_up.x + pos.x, line_up.y)
		else:
			local_pos += Vector2((line_up.x + pos.x)*-1, line_up.y)
		# add state to list
		if state_list:
			state_list.next = StateRunning.towards(local_pos)
		else:
			state_list = StateRunning.towards(local_pos)
	
	return state_list
