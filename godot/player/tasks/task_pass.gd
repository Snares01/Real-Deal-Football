extends Task
class_name TaskPass

@export var cpu := false

func get_state() -> State:
	if cpu:
		return StatePassingCPU.new()
	return StatePassing.new()
