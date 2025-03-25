extends StateSet
class_name StateCoveringZoneSet

#static func cover(zone: Rect2) -> StateCoveringZoneSet:
#	var instance := StateCoveringZoneSet.new()
#	instance.zone = zone
#	return instance

@onready var react_time_left := stats.reaction_time


func _ready() -> void:
	player.velocity = Vector2.ZERO
	player.flip_sprite(true)


func _process(delta: float) -> void:
	if player.on_home_team:
		player.flip_sprite(false)
	else:
		player.flip_sprite(true)
	
	react_time_left -= delta
	if react_time_left < 0.0:
		react_time_left = stats.reaction_time
		# Check if we have to move
		if Globals.is_play_active and _find_target():
			player.set_state(StateCoveringZone.new())

# Override
func handle_event(event: Event) -> void:
	if event != Event.PLAY_START:
		super.handle_event(event)


# Returns true if there's a target we need to move to
func _find_target() -> bool:
	var closest_p: Player
	var closest_dist := INF
	for opp in manager.graph.get_players():
		var opp_pos := opp.position + opp.velocity
		if (opp.on_home_team != player.on_home_team and player.zone.has_point(opp_pos)
		 and not opp.get_state() is StateStanding):
			return true
	return false
