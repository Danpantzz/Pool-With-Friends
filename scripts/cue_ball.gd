extends StaticBody2D

class_name CueBall

signal placed_ball

#var ball_num : int
#var solid : bool
#var eight_ball := false
#enum Ball_Types {solid, striped, eight_ball}
#var ball_type: Ball_Types

var velocity := Vector2.ZERO
var speed = 10

enum States {PLACING, PLACED}
var state: States = States.PLACED

func _physics_process(delta: float) -> void:
	if not get_tree().root.get_node("Main").current_player._id == multiplayer.get_unique_id(): return
	
	if state == States.PLACING:
		var pos = get_viewport().get_mouse_position()
		var direction = (pos - position).normalized()
		
		if (position.distance_to(pos) > speed):
			holding.rpc(direction * speed)
			speed = 10
		else: speed -= 1
		
		if Input.is_action_just_released("click"):
			place_ball.rpc(position)


@rpc("any_peer", "call_local", "reliable")
func holding(pos):
	#position = pos
	move_and_collide(pos)

@rpc("any_peer", "call_local", "reliable")
func place_ball(pos):
	print("place ball")
	position = pos
	placed_ball.emit(pos)
