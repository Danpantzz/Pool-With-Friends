extends ProgressBar

@onready var cue: Sprite2D = %Cue

func _process(delta: float) -> void:
	value = cue.power * (100 / get_tree().root.get_node("Main").MAX_POWER)
