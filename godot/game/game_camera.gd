extends Camera2D

const PASS_PEEK := 150.0 

@onready var player_manager: PlayerManager = get_parent().get_node("PlayerManager")

var pass_pos := 0.0

func _process(delta: float) -> void:
	if player_manager.ball != null:
		# only move camera if ball has gone beyond passing pos
		if ((Globals.drive_dir and player_manager.ball.position.x > pass_pos)
		 or (not Globals.drive_dir and player_manager.ball.position.x < pass_pos)):
			position.x = player_manager.ball.position.x
	elif player_manager.ball_carrier != null:
		position.x = player_manager.ball_carrier.position.x
		if (player_manager.ball_carrier.role == Player.Role.QB):
			if Globals.drive_dir:
				position.x += PASS_PEEK
			else:
				position.x -= PASS_PEEK
			pass_pos = position.x
