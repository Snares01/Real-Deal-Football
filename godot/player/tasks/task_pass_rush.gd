extends Task
class_name TaskPassRush

func get_state() -> State:
	return StateChasing.chase_role(Player.Role.QB)
