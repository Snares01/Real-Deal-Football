extends Node2D
class_name GameManager

const evn := State.Event

@export var stats: PlayerStats

@export var home_offense_call: PlayCall
@export var home_defense_call: PlayCall
@export var away_offense_call: PlayCall
@export var away_defense_call: PlayCall

@onready var player_manager: PlayerManager = $PlayerManager

var is_play_set := false # true when play has been decided & players are lined up
var are_players_lined_up := false
var current_down := 0

func _ready() -> void:
	SignalBus.game_event.connect(_on_game_event)
	await get_tree().create_timer(1.0).timeout
	set_play(home_offense_call, true)
	set_play(away_defense_call, false)


func _process(delta: float) -> void:
	if is_play_set and not are_players_lined_up:
		for player in player_manager.graph.get_players():
			if player.get_state() is not StateSet:
				return
		are_players_lined_up = true
		queue_redraw()


func set_play(play_call: PlayCall, home_team: bool) -> void:
	is_play_set = true
	are_players_lined_up = false
	player_manager.set_play(play_call, home_team)


func start_play() -> void:
	is_play_set = false
	are_players_lined_up = false
	Globals.is_play_active = true
	SignalBus.game_event.emit(State.Event.PLAY_START)
	queue_redraw()
	print("game_manager.gd: down %s | %d yards to 1st down" % [Globals.current_down + 1, abs(Globals.first_down - Globals.scrimmage)])


func _draw() -> void:
	if not is_play_set:
		return
	# Draw play
	for player in player_manager.graph.get_players():
		if player.zone:
			draw_rect(player.zone, Color(Color.RED, 0.2))
		elif player.get_man():
			draw_line(player.position, player.get_man().position, Color(Color.YELLOW, 0.4), 2)


func _input(event: InputEvent) -> void:
	# start play if everyone is lined up
	if are_players_lined_up and event.is_action("select") and not event.is_pressed():
		start_play()


func _on_game_event(event: State.Event) -> void:
	match event:
		evn.INCOMPLETION, evn.OUT_OF_BOUNDS, evn.TOUCHDOWN, evn.BALL_CARRIER_TACKLED:
			_on_play_end(event)

# Called when specific events occur (ie INCOMPLETION), emits PLAY_END event
func _on_play_end(event: State.Event) -> void:
	player_manager.graph.print_graph()
	print("game_manager.gd: play end")
	Globals.is_play_active = false
	Globals.current_down += 1
	# move line of scrimmage
	if player_manager.ball_carrier != null and event != evn.INCOMPLETION:
		var carrier := player_manager.ball_carrier
		Globals.scrimmage = carrier.position.x / Field.YARD
		# change drive dir if ball carrier is on other team
		if carrier.on_home_team != Globals.drive_dir:
			print("game_manager.gd: INTERCEPTION")
			# touchback
			if not carrier.on_home_team and Globals.scrimmage >= 50.0:
				print("game_manager.gd: Touchback")
				Globals.scrimmage = 25.0
			elif carrier.on_home_team and Globals.scrimmage <= 50.0:
				print("game_manager.gd: Touchback")
				Globals.scrimmage = -25.0
			_turnover()
		else:
			# reward first down & move first down marker
			if Globals.drive_dir and Globals.scrimmage >= Globals.first_down:
				Globals.current_down = 0
				Globals.first_down = Globals.scrimmage + 10
			elif not Globals.drive_dir and Globals.scrimmage <= Globals.first_down:
				Globals.current_down = 0
				Globals.first_down = Globals.scrimmage - 10
	# touchdown
	if event == evn.TOUCHDOWN:
		print("game_manager.gd: TOUCHDOWN!!!")
		if Globals.drive_dir:
			Globals.scrimmage = 25.0
			Globals.change_home_score(6)
		else:
			Globals.scrimmage = -25.0
			Globals.change_away_score(6)
		_turnover()
	# turnover on downs
	elif Globals.current_down > 3:
		_turnover()
	# Keep first down out of endzone
	Globals.first_down = clamp(Globals.first_down, -50, 50)
	# End play & update field
	SignalBus.game_event.emit(State.Event.PLAY_END)
	$Field.queue_redraw()
	# start next play
	await get_tree().create_timer(1.0).timeout
	if Globals.drive_dir:
		set_play(home_offense_call, true)
		set_play(away_defense_call, false)
	else:
		set_play(away_offense_call, false)
		set_play(home_defense_call, true)


func _turnover() -> void:
	print("game_manager.gd: turnover")
	Globals.drive_dir = not Globals.drive_dir
	if Globals.drive_dir:
		Globals.first_down = Globals.scrimmage + 10
	else:
		Globals.first_down = Globals.scrimmage - 10
	Globals.current_down = 0
