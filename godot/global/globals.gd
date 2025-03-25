extends Node

signal score_change()
# Game info
var drive_dir := true # home team drives to the right (true)
var is_play_active := false
var scrimmage := 0.0 # in yards, -50 to 50
var first_down := 10.0
var current_down := 0
var _home_score := 0
var _away_score := 0

func get_home_score() -> int:
	return _home_score

func change_home_score(amount: int) -> void:
	_home_score += amount
	score_change.emit()

func get_away_score() -> int:
	return _away_score

func change_away_score(amount: int) -> void:
	_away_score += amount
	score_change.emit()
