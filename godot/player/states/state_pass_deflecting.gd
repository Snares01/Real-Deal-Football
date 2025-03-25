extends State
class_name StatePassDeflecting
# Stop pass from completing. Actual deflection chance happens in attempt_catch in Player

const MAX_DEFLECT_TIME := 0.6

func _init() -> void:
	anim_name = "run_deflect"

func _ready() -> void:
	var timer := get_tree().create_timer(MAX_DEFLECT_TIME)
	timer.timeout.connect(_on_attempt_finished)

func _on_attempt_finished() -> void:
	end_state()
