extends Node2D
class_name PlayerManager
# Manages players and the ball

const BALL := preload("res://ball.tscn")
const PLAYER := preload("res://player/player.tscn")

var ball_carrier: Player = null
var ball: Ball = null # when ball is midair

var graph := PlayerGraph.new()

func create_ball(start_pos: Vector2, throw_input: Vector2) -> void:
	# create ball
	var instance := BALL.instantiate()
	instance.velocity = Ball.swipe_to_velocity(throw_input)
	var vec3_pos := Vector3(start_pos.x, start_pos.y, Ball.THROW_START_HEIGHT)
	instance.vec3_pos = vec3_pos
	instance.position = Vector2(vec3_pos.x, vec3_pos.y - vec3_pos.z)
	add_child(instance)
	# update references
	ball = instance
	ball_carrier = null

# Create / remove players, line up for play
func set_play(play_call: PlayCall, home_team: bool) -> void:
	print("player_manager.gd: set play (%s) %s" % [play_call.play.size(), home_team])
	var play_call_roles := play_call.get_roles()
	for role: Player.Role in play_call_roles:
		# Add / remove players to fit playcall
		while graph.get_role_players(role, home_team).size() < play_call.get_num_players(role):
			add_player(role, home_team)
		while graph.get_role_players(role, home_team).size() > play_call.get_num_players(role):
			remove_player(role, home_team)
		# Make players line up
		var on_offense: bool = (Globals.drive_dir == home_team)
		var role_tasks := play_call.get_role_tasks(role)
		var role_players := graph.get_role_players(role, home_team)
		for i in role_players.size():
			# TODO: Make tackled players get up first
			var line_up_state := role_tasks[i].get_line_up(on_offense)
			role_players[i].set_state(line_up_state)
		# Give Center the ball
		if role == Player.Role.QB:
			if ball:
				ball.queue_free()
				ball = null
			ball_carrier = role_players[0]
	# Remove active players with roles not in play_call
	var players_to_delete: Array[Player] = []
	for player: Player in graph.get_players():
		if player.on_home_team == home_team and player.role not in play_call_roles:
			players_to_delete.append(player)
	for player: Player in players_to_delete:
		delete_player(player)


func add_player(role: Player.Role, on_home_team: bool) -> Player:
	var instance := PLAYER.instantiate()
	instance.role = role
	instance.on_home_team = on_home_team
	graph.add_player(instance)
	add_child(instance)
	instance.position.y = randf_range(-50, 50)
	return instance

# Returns null if player w/ role doesn't exist
func remove_player(role: Player.Role, on_home_team: bool) -> Player:
	for player in graph.get_players():
		if player.role == role and player.on_home_team == on_home_team:
			return delete_player(player)
	return null

# I would also call this function remove_player IF GDSCRIPT LET MEEE
func delete_player(player: Player) -> Player:
	graph.remove_player(player)
	player.queue_free()
	return player
