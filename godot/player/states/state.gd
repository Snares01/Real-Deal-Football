extends Node
class_name State

enum Event { # Events that could cause state transitions
	PLAY_END,
	PLAY_START,
	INCOMPLETION,
	OUT_OF_BOUNDS,
	BALL_NEARBY,
	BALL_CAUGHT,
	TOUCHDOWN,
	BALL_CARRIER_TACKLED
}

const INTERCEPT_MARGIN := 20.0 # Make this part of playerstats

@onready var stats: PlayerStats = player.stats

var next: State # For transitioning to next state
# Set by Player
var manager: PlayerManager
var player: Player
# Set on init in subclasses
var interrupting := false # will return to previous state when done
var anim_name: String
var ball_anim_name: String


func end_state() -> void:
	if next:
		player.set_state(next)
	elif interrupting:
		player.continue_previous_state()
	else:
		player.set_state(StateStanding.new())

# Called by Player when state is interrupted
func on_interruption() -> void:
	pass

# Handle transitions to other states
func handle_event(event: Event) -> void:
	match event:
		Event.PLAY_END:
			player.set_state(StateStanding.new())
		Event.BALL_NEARBY:
			if player.role in [Player.Role.WR, Player.Role.QB]:
				player.set_state(StateCatching.new())
			elif player.on_home_team != Globals.drive_dir:
				# Go for interception / pass block
				if player.get_man() == null:
					player.set_state(StateCatching.new())
				else:
					# Only go for interception if closer to ball than receiver
					var man_ball_dist := player.get_man().position.distance_to(manager.ball.position)
					var player_ball_dist := player.position.distance_to(manager.ball.position)
					if player_ball_dist < (man_ball_dist - INTERCEPT_MARGIN):
						player.set_state(StateCatching.new())
					else:
						player.set_state(StatePassDeflecting.new())
		Event.BALL_CAUGHT:
			if manager.ball_carrier.on_home_team != player.on_home_team:
				# Chase player on other team
				player.set_state(StateChasing.chase_man(manager.ball_carrier))
			elif manager.ball_carrier.on_home_team == player.on_home_team:
				# Block for player on our team
				player.set_state(StateFindingBlock.block_for(manager.ball_carrier))
