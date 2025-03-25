extends Resource
class_name PlayerGraph
# Keeps references to active players & their relationships

enum Relation {
	NONE,
	COVERING,
	COVERED,
	CHASING,
	CHASED, # Player is being targeted for tackle or block
	PROTECTING, # Blocking for player
	PROTECTED, # Player is blocking for me
	BLOCKING, # Hunting player for block or actively blocking player
	BLOCKED, # Player is targeting me for a block or actively blocking me
}

var _matrix_size := 0
var _players: Array[Player]
var _matrix: Array[Array] # 2D array of Relations

func get_players() -> Array[Player]:
	return _players

# Returns Array[Relation]
# Gets things being done to a player
func get_relations(player: Player) -> Array[Relation]:
	var relations: Array[Relation] = []
	var index := _players.find(player)
	for arr: Array in _matrix:
		relations.append(arr[index])
	return relations

# Returns things a player is doing
func get_actions(player: Player) -> Array[Relation]:
	var actions: Array[Relation] = []
	var index := _players.find(player)
	for item in _matrix[index]:
		actions.append(item) # just returning _matrix[i] gives return type error
	return actions

# Returns list of players that are acting upon the given player
# State ex: graph.get_action_players(player, Relation.COVERING) will get 
# the players that are covering the player
func get_player_relations(player: Player, relation: Relation) -> Array[Player]:
	var players_acting_upon_you: Array[Player] = []
	var i := _players.find(player)
	for j in _matrix_size:
		if _matrix[i][j] == relation:
			players_acting_upon_you.append(_players[j])
	
	return players_acting_upon_you

# Returns list of players that the player is acting on
# State ex: graph.get_action_players(player, Relation.COVERED) will get 
# the players that the player must cover
func get_player_actions(player: Player, relation: Relation) -> Array[Player]:
	var player_to_act_upon: Array[Player] = []
	var i := _players.find(player)
	for j in _matrix_size:
		if _matrix[j][i] == relation:
			player_to_act_upon.append(_players[j])
	
	return player_to_act_upon

func get_all_relations() -> Dictionary[Player, Array]:
	var output: Dictionary[Player, Array] = {}
	for player in _players:
		output[player] = get_relations(player)
	return output

func get_all_actions() -> Dictionary[Player, Array]:
	var output: Dictionary[Player, Array] = {}
	for player in _players:
		output[player] = get_actions(player)
	return output


func add_player(player: Player) -> void:
	_players.append(player)
	# Increase matrix size
	_matrix_size += 1
	_matrix.append([Relation.NONE]) # Column will at least have 1 entry
	for row: Array in _matrix:
		while row.size() < _matrix_size:
			row.append(Relation.NONE)

# Assumes player exists in graph
func remove_player(player: Player) -> void:
	var index := _players.find(player)
	_players.remove_at(index)
	# remove from matrix
	_matrix_size -= 1
	_matrix.remove_at(index)
	for row: Array in _matrix:
		row.remove_at(index)


func add_relation(to: Player, from: Player, relation: Relation) -> void:
	var to_index := _players.find(to)
	var from_index := _players.find(from)
	
	_matrix[to_index][from_index] = relation
	_matrix[from_index][to_index] = _get_matching_relation(relation)

func remove_relation(to: Player, from: Player) -> void:
	var to_index := _players.find(to)
	var from_index := _players.find(from)
	
	_matrix[to_index][from_index] = Relation.NONE
	_matrix[from_index][to_index] = Relation.NONE

func print_graph() -> void:
	print("START GRAPH")
	for i: int in _matrix.size():
		var new_str := ""
		for j: Relation in _matrix[i]:
			new_str += str(j) + " "
		print(new_str)

func get_role_players(role: Player.Role, on_home_team: bool) -> Array[Player]:
	var output: Array[Player] = []
	for player: Player in _players:
		if player.role == role and player.on_home_team == on_home_team:
			output.append(player)
	return output

func _get_matching_relation(relation: Relation) -> Relation:
	match relation:
		Relation.COVERING:
			return Relation.COVERED
		Relation.CHASING:
			return Relation.CHASED
		Relation.PROTECTING:
			return Relation.PROTECTED
		Relation.BLOCKING:
			return Relation.BLOCKED
	return relation
