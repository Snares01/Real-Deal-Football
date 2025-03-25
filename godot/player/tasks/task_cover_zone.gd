extends Task
class_name TaskCoverZone

@export var zone: Rect2

func get_state() -> State:
	return null # not used by get_line_up


func get_line_up(offense: bool) -> State:
	# Makes its own post-snap state after 
	return StateCoveringZone.cover(zone)
