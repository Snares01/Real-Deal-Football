extends State
class_name StateStanding

const FRICTION := 100.0

func _init() -> void:
	anim_name = "stand"


func _process(delta: float) -> void:
	# Slow down
	if player.velocity.length() > 0.0:
		player.velocity = (player.velocity.normalized()
		 * move_toward(player.velocity.length(), 0, delta * FRICTION))
