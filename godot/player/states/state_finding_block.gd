extends StateRunning
class_name StateFindingBlock
# Get between players to start a block

static func block_for(player: Player) -> StateFindingBlock:
	var instance := StateFindingBlock.new()
	instance.p_protect = player
	return instance

const BLOCK_LEAD := 2.0 # Multiplier increasing distance in front of p_protect
const BLOCK_DIST := 10.0 # Distance to initiate block
const CATCH_UP_DIST := 100.0 # If p_protect is this far, stop blocking & catch up
const MIN_TACKLE_TIME := 0.8
const TACKLE_TIME_MULT := 2.0
const TACKLE_CHANCE := 0.5
const SPEED_TACKLE_TIME := 1.0 # duration of tackle when outrunning a player head-on
const SIDE_TACKLE_TIME := 1.2 # hitting off angle
const DOUBLE_TEAM_TACKLE_TIME := 1.5 # second blocker to hit

var p_protect: Player
var p_block: Player # set in _ready()


func _ready() -> void:
	# add / remove relations (these signals work for state interruptions)
	tree_entered.connect(_on_tree_entered)
	tree_exited.connect(_on_tree_exited)
	_on_tree_entered()

func _process(delta: float) -> void:
	if p_protect == null:
		end_state()
	elif p_block == null:
		var dir_to_p_protect := player.position.direction_to(p_protect.position)
		# Only assign blocker if we don't need to catch up to player
		if (player.position.distance_to(p_protect.position) < CATCH_UP_DIST
		 or player.velocity.normalized().dot(dir_to_p_protect) < 0.0):
			p_block = _get_block_assignment()
			if p_block:
				manager.graph.add_relation(p_block, player, PlayerGraph.Relation.BLOCKING)
		lead_player()
	else:
		target_pos = player.get_player_interception_pos(p_block)
		if p_block.get_state() is StateTackled:
			_drop_block()
	super._process(delta)

# Override
func on_target_reached() -> void:
	if not p_block or not player.position.distance_to(p_block.position) < BLOCK_DIST:
		return
	# double team tackle
	if p_block.get_state() is StateShoved or p_block.get_state() is StateWrestling:
		p_block.set_state(StateTackled.tackle(DOUBLE_TEAM_TACKLE_TIME, player.velocity))
		return
	# its blocking time
	var total_velocity := player.velocity.length() + p_block.velocity.length()
	#var velocity_diff := (player.velocity - p_block.velocity).length() / total_velocity
	var target_vel := p_block.velocity.length()
	var blocker_vel := player.velocity.length()
	var ang_to_target := player.velocity.normalized().dot(
		player.position.direction_to(p_block.position)
	)
	var ang_to_blocker := p_block.velocity.normalized().dot(
		p_block.position.direction_to(player.position)
	)
	
	# really slow collision
	if total_velocity < 40.0:
		p_block.set_state(StateWrestling.wrestle(player))
		player.set_state(StateWrestling.wrestle(p_block))
	elif abs(ang_to_target - ang_to_blocker) < 0.1:
		# slow collision
		if total_velocity < 80.0:
			p_block.set_state(StateWrestling.wrestle(player))
			player.set_state(StateWrestling.wrestle(p_block))
		# direct collision
		elif blocker_vel > target_vel * 2.0:
			# we win
			var rand := randf()
			# Make this dependent on strength stat or something
			if rand < TACKLE_CHANCE:
				player.velocity = Vector2.ZERO
				p_block.set_state(StateTackled.tackle(SPEED_TACKLE_TIME, player.velocity))
			else:
				player.velocity = Vector2.ZERO
				p_block.set_state(StateShoved.shove(player, player.velocity))
		elif target_vel > blocker_vel * 2.0:
			# target wins
			var rand := randf()
			# Make this also dependent on strength stat
			if rand < TACKLE_CHANCE:
				p_block.velocity = Vector2.ZERO
				player.set_state(StateTackled.tackle(SPEED_TACKLE_TIME, p_block.velocity))
			else:
				p_block.velocity = Vector2.ZERO
				player.set_state(StateShoved.shove(p_block, p_block.velocity))
		else:
			p_block.set_state(StateShoved.shove(player, player.velocity))
			player.set_state(StateShoved.shove(p_block, p_block.velocity))
	else:
		# off-angle collision
		if ang_to_target > ang_to_blocker:
			player.velocity = Vector2.ZERO
			p_block.set_state(StateTackled.tackle(SPEED_TACKLE_TIME, player.velocity))
		else:
			p_block.velocity = Vector2.ZERO
			player.set_state(StateTackled.tackle(SPEED_TACKLE_TIME, player.velocity))
	
	#player.set_state(StateTackled.tackle(max(MIN_TACKLE_TIME, abs(velocity_diff) * TACKLE_TIME_MULT), p_block.velocity))
	
	#player.set_state(StateShoved.shove(p_block, p_block.velocity))
	#p_block.set_state(StateShoved.shove(player, player.velocity))

# Overriden in subclass StateProtectingPasser
func lead_player() -> void:
	target_pos = p_protect.position + (p_protect.velocity * BLOCK_LEAD)

# Find player to block
func _get_block_assignment() -> Player:
	# TODO: Take into account distance from p_protect
	# Block player with least blockers / closest to self
	var chasing := manager.graph.get_player_relations(p_protect, PlayerGraph.Relation.CHASING)
	var closest_p: Player
	var closest_dist := INF
	for chaser: Player in chasing:
		if (not chaser.get_state() is StateChasing):
			continue
		var dist := player.position.distance_squared_to(chaser.position)
		# If an existing blocker is significantly closer than us, ignore this player
		var existing_blockers := manager.graph.get_player_relations(chaser, PlayerGraph.Relation.BLOCKING)
		var already_blocked := false
		for blocker in existing_blockers:
			if (blocker.position.distance_squared_to(chaser.position) < dist * 0.8):
				already_blocked = true
		if already_blocked:
			continue
		# Pick player we are closest to
		if dist < closest_dist:
			closest_dist = dist
			closest_p = chaser
	return closest_p


func _drop_block() -> void:
	manager.graph.remove_relation(p_block, player)
	p_block = null


func _on_tree_entered() -> void:
	if p_protect:
		manager.graph.add_relation(p_protect, player, PlayerGraph.Relation.PROTECTING)
	if p_block:
		manager.graph.add_relation(p_block, player, PlayerGraph.Relation.BLOCKING)


func _on_tree_exited() -> void:
	if p_protect:
		manager.graph.remove_relation(p_protect, player)
	if p_block:
		manager.graph.remove_relation(p_block, player)
