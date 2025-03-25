extends Node2D
class_name ThrowArc

var throw_swipe := Vector2.ZERO
var player: Player

func update_throw(swipe: Vector2) -> void:
	throw_swipe = swipe
	queue_redraw()


func _process(delta: float) -> void:
	if player:
		position = player.position


func _draw():
	if throw_swipe == Vector2.ZERO:
		return
	var vec3_points: Array[Vector3] = Ball.get_arc_points(throw_swipe)
	var vec2_points: Array[Vector2] = []
	for pos in vec3_points:
		vec2_points.append(Vector2(pos.x, pos.y - pos.z))
	
	draw_polyline(vec2_points, Color(0.1, 0.1, 1.0, 0.8), 1.1)
