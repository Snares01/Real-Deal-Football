extends Control

@onready var home_score: Label = $"%HomeScore"
@onready var away_score: Label = $"%AwayScore"


func _ready() -> void:
	Globals.score_change.connect(_on_score_change)


func _on_score_change() -> void:
	home_score.text = str(Globals.get_home_score())
	away_score.text = str(Globals.get_away_score())
