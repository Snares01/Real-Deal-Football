extends StateFindingBlock
class_name StateProtectingPasser

const SCRIMMAGE_MARGIN := 35.0

var qb_offset: Vector2 # Position relative to qb at start

func _ready() -> void:
	if manager.ball_carrier:
		p_protect = manager.ball_carrier
		qb_offset = (player.position - p_protect.position) / 1.5
	else:
		end_state()
	super._ready()

# Override
func on_target_reached() -> void:
	# TODO: Go to resting position if at qb_offset position
	super.on_target_reached()

# Override
func _get_block_assignment() -> Player:
	var assignment := super._get_block_assignment()
	# Don't chase people beyond line of scrimmage
	if assignment:
		var right_of_scrimmage: bool = assignment.position.x > Globals.scrimmage * Field.YARD
		var dist: float = abs(assignment.position.x - (Globals.scrimmage * Field.YARD))
		if Globals.drive_dir == right_of_scrimmage and dist > SCRIMMAGE_MARGIN:
			assignment = null
	return assignment

# Override
func lead_player() -> void:
	target_pos = p_protect.position + qb_offset
	p_block = _get_block_assignment()
	if p_block:
		manager.graph.add_relation(p_block, player, PlayerGraph.Relation.BLOCKING)
