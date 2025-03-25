extends State
class_name StatePassing

@onready var throw_arc := ThrowArc.new()

var is_aiming := false
var drag_start: Vector2

func _init() -> void:
	anim_name = "stand_ball"


func _ready() -> void:
	add_child(throw_arc)
	throw_arc.player = player
	if manager.ball_carrier != player:
		print("state_passing.gd: passer doesn't have ball")
		player.set_state(StateStanding.new())


func _process(delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("select"):
		is_aiming = true
		drag_start = mouse_pos
	elif Input.is_action_just_released("select") and is_aiming:
		is_aiming = false
		# TODO: cancel throwing ball if throw distance is super duper short
		# throw ball, switch to standing state
		player.manager.create_ball(player.position, drag_start - mouse_pos)
		end_state()
	# aim
	if is_aiming:
		throw_arc.update_throw(drag_start - mouse_pos)


func on_interruption() -> void:
	is_aiming = false
	throw_arc.update_throw(Vector2.ZERO)
