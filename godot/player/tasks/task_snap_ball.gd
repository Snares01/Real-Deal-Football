extends Task
class_name TaskSnapBall

func get_state() -> State:
	var state := StateSnapBall.new()
	state.next = StateProtectingPasser.new()
	return state
