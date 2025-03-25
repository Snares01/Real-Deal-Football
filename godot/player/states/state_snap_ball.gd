extends State
class_name StateSnapBall
# Short delay for center before they can block

const SNAP := Vector2(-50, 0)

func _init() -> void:
	anim_name = "snap"

func _ready() -> void:
	player.animator.animation_finished.connect(_on_anim_finished)


func _on_anim_finished(_anim_name: String) -> void:
	end_state()
