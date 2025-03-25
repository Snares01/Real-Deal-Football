extends Resource
class_name PlayBook

var _plays: Array[PlayCall]


func load_plays() -> void:
	pass


func get_plays() -> Array[PlayCall]:
	return _plays
