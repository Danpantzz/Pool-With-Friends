extends ProgressBar

@onready var cue: Cue = %CueBase

func _process(delta: float) -> void:
	value = cue.power * (100 / get_tree().root.get_node("Main").MAX_POWER)
