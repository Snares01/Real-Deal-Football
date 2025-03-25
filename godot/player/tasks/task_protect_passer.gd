extends Task
class_name TaskProtectPasser

func get_state() -> State:
	return StateProtectingPasser.new()
