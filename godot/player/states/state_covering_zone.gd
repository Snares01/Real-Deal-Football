extends StateRunning
class_name StateCoveringZone

static func cover(zone: Rect2) -> StateCoveringZone:
	var instance := StateCoveringZone.new()
	instance.zone = zone
	return instance

@onready var react_time_left := stats.reaction_time

var zone: Rect2
var man: Player


func _ready() -> void:
	# Translate zone to actual position
	if player.zone:
		zone = player.zone
	else:
		if player.on_home_team:
			zone.position.x  = -zone.position.x - zone.size.x
		zone.position.x += Globals.scrimmage * Field.YARD
		player.zone = zone
	
	_update_target()


func _process(delta: float) -> void:
	if Globals.is_play_active:
		# Update reaction / get new target
		react_time_left -= delta
		if react_time_left < 0.0:
			react_time_left = stats.reaction_time
			_update_target()
		# Follow target
		if man != null:
			target_pos = man.position + (man.velocity * stats.predict_dist)
		else:
			target_pos = zone.get_center()
	else:
		# Move to line up
		target_pos = zone.get_center()
	
	super._process(delta)


func on_target_reached() -> void:
	if ((not Globals.is_play_active) or (man and man.get_state() is StateStanding)
	 or (man == null)):
		player.set_man(null)
		player.set_state(StateCoveringZoneSet.new())

# Cover player closest to center of zone
func _update_target() -> void:
	var closest_p: Player
	var closest_dist := INF
	for opp in manager.graph.get_players():
		var opp_pos := opp.position + opp.velocity
		if (opp.on_home_team != player.on_home_team and zone.has_point(opp_pos)):
			var opp_dist := zone.get_center().distance_squared_to(opp_pos)
			if opp_dist < closest_dist:
				closest_dist = opp_dist
				closest_p = opp
	player.set_man(closest_p, PlayerGraph.Relation.COVERING)
	man = player.get_man()
