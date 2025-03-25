extends State
class_name StateSet # Lined-up & ready for the next play

const MIN_LINE_DIST := 6.0

func _init() -> void:
	anim_name = "set"
	ball_anim_name = "set"


func _ready() -> void:
	if player.on_home_team:
		player.flip_sprite(false)
		player.position.x = min((Globals.scrimmage * Field.YARD) - MIN_LINE_DIST, player.position.x)
	else:
		player.flip_sprite(true)
		player.position.x = max((Globals.scrimmage * Field.YARD) + MIN_LINE_DIST, player.position.x)


func _process(delta: float) -> void:
	player.velocity = Vector2.ZERO
	if player.on_home_team:
		player.flip_sprite(false)
	else:
		player.flip_sprite(true)


func handle_event(event: Event) -> void:
	if event == Event.PLAY_START:
		end_state()
	super.handle_event(event)
