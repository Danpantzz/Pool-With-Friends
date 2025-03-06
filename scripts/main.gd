extends Node

@export var ball_scene : PackedScene

#@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
#@onready var lobby: PanelContainer = $CanvasLayer/Lobby

@onready var table: Sprite2D = %Table
@onready var cue: Cue = %Cue
@onready var power_bar: ProgressBar = %PowerBar
@onready var potted_grid: GridContainer = %PottedGrid

# game variables
var ball_images := []
var cue_ball
const START_POS := Vector2(890, 340)
const MAX_POWER := 7.0
var taking_shot : bool
const MOVE_THRESHOLD := 5.0
var cue_ball_potted : bool
var potted := []
var game_started := true

# multiplayer variables
var players = 0
var player: Player_Info
var turn = 0


##### Game Logic #####
func _ready() -> void:
	load_images()
	set_up_players()
	new_game()
	
	# Set up pockets connection to potted ball function
	table.get_node("Pockets").body_entered.connect(potted_ball)

func _process(_delta) -> void:
	if not game_started: return
	
	var moving := false
	
	# check that all balls have stopped moving
	for b in get_tree().get_nodes_in_group("balls"):
		if (b.linear_velocity.length() > 0.0 and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
			
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
	
	if player.my_turn:
		if not moving:
			# check if cue ball has been potted and reset it
			if cue_ball_potted:
				reset_cue_ball()
				cue_ball_potted = false
			
			if not taking_shot:
				taking_shot = true
				show_cue.rpc()
		else:
			if taking_shot:
				taking_shot = false
				hide_cue.rpc()
	else:
		cue.set_physics_process(false)

func load_images():
	for i in range(1, 17, 1):
		var filename = str("res://assets/balls/ball_", i, ".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)

func set_up_players():
	players = Lobby.players.size()
	
	for p in Lobby.players:
		p.my_turn = false
		if p._id == multiplayer.get_unique_id():
			player = p
	
	Lobby.players[turn].my_turn = true

func new_game():
	cue_ball_potted = false
	clear_balls()
	generate_balls()
	reset_cue_ball()
	show_cue()
	game_started = true

func clear_balls():
	get_tree().call_group("balls", "queue_free")
	for b in potted:
		b.queue_free()

func generate_balls():
	# setup game balls
	var count : int = 0
	var rows : int = 5
	var dia = 36
	for col in range(5):
		for row in range(rows):
			var b : Ball = ball_scene.instantiate()
			var pos = Vector2(250 + (col * (dia)), 267 + (row * (dia)) + (col * dia / 2))
			add_child.call_deferred(b)
			
			# set ball to solid or striped
			if count < 7: b.ball_type = b.Ball_Types.solid
			elif count == 7: b.ball_type = b.Ball_Types.eight_ball
			else: b.ball_type = b.Ball_Types.striped
			
			b.ball_num = count + 1
			b.position = pos
			b.get_node("Sprite2D").texture = ball_images[count]
			count += 1
		rows -= 1

func remove_cue_ball():
	var old_b = cue_ball
	remove_child(old_b)
	old_b.queue_free()

func reset_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball)
	cue_ball.position = START_POS
	cue_ball.get_node("Sprite2D").texture = ball_images.back()
	taking_shot = false

@rpc("any_peer", "call_local", "reliable")
func show_cue():
	cue.set_physics_process(true)
	cue.position = cue_ball.position
	power_bar.position.x = cue_ball.position.x - (0.5 * power_bar.size.x)
	power_bar.position.y = cue_ball.position.y + power_bar.size.y
	cue.show()
	power_bar.show()

@rpc("any_peer", "call_local", "reliable")
func hide_cue():
	cue.set_physics_process(false)
	cue.hide()
	power_bar.hide()

@rpc("any_peer", "call_local", "reliable")
func _on_cue_shoot(power) -> void:
	cue_ball.apply_central_impulse(power)
	turn += 1
	if (turn >= Lobby.players.size()): turn = 0
	set_up_players()


func potted_ball(body: Ball):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	elif body.ball_type == body.Ball_Types.eight_ball:
		new_game()
	else:
		var b = TextureRect.new()
		potted_grid.add_child(b)
		b.texture = body.get_node("Sprite2D").texture
		potted.append(b)
		body.queue_free()

func game_over():
	hide_cue()
	get_tree().paused = true
	
