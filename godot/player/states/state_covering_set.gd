extends StateSet
class_name StateCoveringSet
# Created by StateCovering, transitions back to StateCovering
# Assumes "man" in Player isn't null

static func covering(dist_from_line: float) -> StateCoveringSet:
	var instance := StateCoveringSet.new()
	instance.dist_from_line = dist_from_line
	return instance

var dist_from_line: float
var man: Player

func _ready() -> void:
	player.velocity = Vector2.ZERO
	man = player.get_man()
	if not Globals.is_play_active:
		if player.on_home_team:
			player.position.x = min((Globals.scrimmage * Field.YARD) - MIN_LINE_DIST, player.position.x)
		else:
			player.position.x = max((Globals.scrimmage * Field.YARD) + MIN_LINE_DIST, player.position.x)
	# transition to StateCovering
	next = StateCovering.cover_man(dist_from_line)


func _process(delta: float) -> void:
	if player.on_home_team:
		player.flip_sprite(false)
	else:
		player.flip_sprite(true)
	# transition to StateCovering
	if ((not man.get_state() is StateSet)
	 and (not man.get_state() is StateStanding)):
		end_state()
