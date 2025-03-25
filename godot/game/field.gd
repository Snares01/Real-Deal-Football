extends Node2D
class_name Field

const YARD := 12.0 # pixels in a yard
const Y := YARD
const HEIGHT := 30.0 # height of field in yards (width is assumed 100 yards)
const ENDZONE_WIDTH := 10.0
const COL_GRASS := Color("3ac764")
const COL_MARK := Color("cef1d8")
const COL_ENDZONE_AWAY := Color("0e32d8")
const COL_ENDZONE_HOME := Color("d85114")
const COL_SCRIMMAGE := Color("0056e0", 0.66)
const COL_FIRST_DOWN := Color("f7f700", 0.66)

func _draw() -> void:
	# draw main field
	draw_rect(Rect2(-50*Y, (-HEIGHT/2)*Y, 100*Y, HEIGHT*Y), COL_GRASS)
	# 5-yard markers
	for i in range(-50*Y, 55*Y, 5*Y):
		draw_line(Vector2(i, (-HEIGHT/2)*Y), Vector2(i, (HEIGHT/2)*Y), COL_MARK, 2)
	# yard markers
	for i in range(-50*Y, 50*Y, Y):
		draw_line(Vector2(i, (-HEIGHT/2)*Y), Vector2(i, (-HEIGHT/2)*Y + Y), COL_MARK, 2)
		draw_line(Vector2(i, (HEIGHT/2)*Y), Vector2(i, (HEIGHT/2)*Y - Y), COL_MARK, 2)
		
		draw_line(Vector2(i, (-HEIGHT/6)*Y), Vector2(i, ((-HEIGHT/6)*Y) + Y), COL_MARK, 2)
		draw_line(Vector2(i, (HEIGHT/6)*Y), Vector2(i, ((HEIGHT/6)*Y) - Y), COL_MARK, 2)
	# out of bounds
	draw_line(Vector2((-ENDZONE_WIDTH-50)*Y, (HEIGHT/2)*Y), Vector2((50+ENDZONE_WIDTH)*Y, (HEIGHT/2)*Y), COL_MARK, 2)
	draw_line(Vector2((-ENDZONE_WIDTH-50)*Y, (-HEIGHT/2)*Y), Vector2((50+ENDZONE_WIDTH)*Y, (-HEIGHT/2)*Y), COL_MARK, 2)
	# endzones
	draw_rect(Rect2((-ENDZONE_WIDTH-50)*Y, (-HEIGHT/2)*Y, ENDZONE_WIDTH*Y, HEIGHT*Y), COL_ENDZONE_AWAY)
	draw_rect(Rect2(50*Y, (-HEIGHT/2)*Y, ENDZONE_WIDTH*Y, HEIGHT*Y), COL_ENDZONE_HOME)
	# line of scrimmage / first down
	draw_line(Vector2(Globals.scrimmage*Y, (-HEIGHT*Y)/2), Vector2(Globals.scrimmage*Y, (HEIGHT*Y)/2), COL_SCRIMMAGE, 3)
	draw_line(Vector2(Globals.first_down*Y, (-HEIGHT*Y)/2), Vector2(Globals.first_down*Y, (HEIGHT*Y)/2), COL_FIRST_DOWN, 3)
