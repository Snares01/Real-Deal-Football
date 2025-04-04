extends Resource
class_name PlayerStats

const Role := Player.Role

# Load with default stats
static func new_default(role: Player.Role) -> PlayerStats:
	var stats := PlayerStats.new()
	
	match role:
		Role.OT, Role.OG, Role.C, Role.DT, Role.DE:
			stats.run_accel = 50.0
			stats.run_speed = 30.0
			stats.sprint_accel = 20.0
			stats.sprint_speed = 50.0
			stats.weight = 250.0
			stats.strength = 150.0
		Role.WR:
			stats.run_accel = 90.0
			stats.sprint_accel = 45.0
		Role.DB:
			stats.sprint_speed = 50.0 # 80
			stats.reaction_time = randf_range(0.3, 1.0)
			stats.predict_dist = randf_range(0.0, 3.0)
		Role.DT, Role.DE:
			stats.strength = 200.0
			stats.weight = 150.0
	return stats

@export var run_accel := 70.0 # Acceleration up to run_speed
@export var sprint_accel := 30.0 # Acceleration up to sprint_speed
@export var run_speed := 50.0
@export var sprint_speed := 70.0
@export var weight := 100.0
@export var strength := 100.0
@export var reaction_time := 0.5 # For man coverage
@export var predict_dist := 1.0 # How far DB goes to predict movement
@export_range(0.0, 1.0) var anger := randf() # Avoidant / angry run-style
