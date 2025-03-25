extends Task
class_name TaskCoverMan

@export var role_to_cover: Player.Role

func get_state() -> State:
	return null # not used by get_line_up


func get_line_up(offense: bool) -> State:
	# Makes its own post-snap state after 
	return StateCovering.cover_role(role_to_cover, abs(line_up.x))
