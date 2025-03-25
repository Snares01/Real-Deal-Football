extends Resource
class_name PlayCall # Contains tasks for each player & helper functions

@export var play: Array[Task]

# Get list of roles used in play
func get_roles() -> Array[Player.Role]:
	var output: Array[Player.Role] = []
	for task: Task in play:
		if task.role not in output:
			output.append(task.role)
	return output

# Get number of players with given role
func get_num_players(role: Player.Role) -> int:
	var output := 0
	for task: Task in play:
		if task.role == role:
			output += 1
	return output

# Get list of tasks for a given role
func get_role_tasks(role: Player.Role) -> Array[Task]:
	var output: Array[Task] = []
	for task in play:
		if task.role == role:
			output.append(task)
	return output
