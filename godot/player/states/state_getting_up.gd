extends State
class_name StateGettingUp

func _init() -> void:
	interrupting = true
	anim_name = "get_up"


func _ready() -> void:
	player.animator.animation_finished.connect(_on_anim_finished)


func _on_anim_finished(_anim_name: String) -> void:
	end_state()
