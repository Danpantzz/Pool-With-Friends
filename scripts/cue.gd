extends Sprite2D

class_name Cue

signal shoot

var power : float = 0.0
var power_dir = 1

func _physics_process(delta: float) -> void:
	if not get_tree().root.get_node("Main").game_started: return
	
	# if not my turn, return
	if not get_tree().root.get_node("Main").current_player == multiplayer.get_unique_id(): return
	
	var mouse_pos := get_viewport().get_mouse_position()
	look_at(mouse_pos)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		power += 0.1 * power_dir
		if power >= get_tree().root.get_node("Main").MAX_POWER:
			power_dir = -1
		elif power <= 0:
			power_dir = 1
		#print(power)
	else:
		power_dir = 1
		if power > 0:
			var dir = mouse_pos - position
			_shoot.rpc(power, dir)
			#shoot.emit(power * dir)
			power = 0

@rpc("any_peer", "call_local", "reliable")
func _shoot(pow, dir):
	shoot.emit(pow * dir)
	#power = 0
