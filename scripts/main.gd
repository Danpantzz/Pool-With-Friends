extends Node

@export var ball_scene : PackedScene
@export var place_cue_ball_scene : PackedScene

#@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu
#@onready var lobby: PanelContainer = $CanvasLayer/Lobby

@onready var table: Sprite2D = %Table
@onready var cue: Cue = %Cue
@onready var power_bar: ProgressBar = %PowerBar
@onready var potted_grid: GridContainer = %PottedGrid
@onready var name_label: Label = %NameLabel
@onready var ball_type: Label = %BallType

# game variables
var ball_images := []
var cue_ball
var cue_ball_placeholder
const START_POS := Vector2(890, 340)
const MAX_POWER := 7.0
var taking_shot : bool
const MOVE_THRESHOLD := 5.0
var cue_ball_potted : bool
var placing_cue_ball : bool
var potted := []
var potted_this_turn := []
var game_started := true
var ball_type_chosen : bool

# multiplayer variables
var players = 0
var team_1_players := []
var team_1_turns := 0
var team_2_players := []
var team_2_turns := 0
var current_player = Lobby.players[0]
var turn = 0
var current_team

##### Game Logic #####
func _ready() -> void:
	if not multiplayer.is_server(): return
	load_images.rpc()
	set_up_players.rpc()
	new_game.rpc()
	
	# Set up pockets connection to potted ball function
	connect_pockets.rpc()

func _process(_delta) -> void:
	if not game_started: return
	
	var moving := false
	
	# check that all balls have stopped moving
	for b in get_tree().get_nodes_in_group("balls"):
		if (b.linear_velocity.length() > 0.0 and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
			
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
	
	# do rest of logic only on host
	if not multiplayer.get_unique_id() == 1: return
	
	if not moving:
		# check if cue ball has been potted and reset it
		if cue_ball_potted && not placing_cue_ball:
			next_turn.rpc()
			scratched.rpc()
		
		if (ball_type_chosen):
			if cue_ball && (cue_ball.ball_hit == null || cue_ball.ball_hit != current_player.ball_to_hit) && not taking_shot && not placing_cue_ball:
				if cue_ball.ball_hit:
					print("Ball hit: ", cue_ball.ball_hit)
				print("Ball to hit: ", current_player.ball_to_hit)
				remove_cue_ball.rpc()
				next_turn.rpc()
				scratched.rpc()
			
			# if (hit correct ball && no balls potted || wrong ball type potted) && not taking_shot && not placing_cue_ball:
			elif cue_ball && (cue_ball.ball_hit == null || cue_ball.ball_hit == current_player.ball_to_hit) && not taking_shot && not placing_cue_ball:
				var go_again = false
				if potted_this_turn.size() > 0:
					for ball in potted_this_turn:
						if (ball == current_player.ball_to_hit):
							print("go again")
							go_again = true
							break
							
				if not go_again:
					next_turn.rpc()
					#show_cue.rpc()

		elif not taking_shot && not placing_cue_ball:
			var go_again = false
			
			if potted_this_turn.size() > 0:
				current_player.ball_to_hit = potted_this_turn[0]
				ball_type_chosen = true
				go_again = true
				
				#var ball = inst_to_dict(current_player.ball_to_hit)
				set_up_ball_type.rpc(current_player.ball_to_hit)
				
			if not go_again:
				next_turn.rpc()
				#show_cue.rpc()
		
		# fires first, and after every shot
		if not taking_shot && not placing_cue_ball:
			potted_this_turn = []
			cue_ball.ball_hit = -1
			cue_ball.first_ball_hit = false
			taking_shot = true
			show_cue.rpc()
			set_up_players.rpc()
			
	else:
		if taking_shot:
			taking_shot = false
			hide_cue.rpc()

@rpc("any_peer", "call_local", "reliable")
func load_images():
	for i in range(1, 17, 1):
		var filename = str("res://assets/balls/ball_", i, ".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)

@rpc("any_peer", "call_local", "reliable")
func set_up_players():
	players = Lobby.players.size()
	team_1_players = []
	team_2_players = []
	
	for player in Lobby.players:
		if player.team == 1:
			team_1_players.append(player)
		elif player.team == 2:
			team_2_players.append(player)
			
	#if current_player.team == 1:
	name_label.text = "Current Player: %s" % current_player.name
	
	if current_player.ball_to_hit == 0:
		ball_type.text = "Ball Type: Solids"
	elif current_player.ball_to_hit == 1:
		ball_type.text = "Ball Type: Stripes"

@rpc("any_peer", "call_local", "reliable")
func next_turn():
	current_player.my_turn = false
	set_up_players()
	
	# if current player is team 1, go to next team 2 player
	if current_player.team == 1 || team_1_players.size() == 0:
		if team_2_players.size() == 0: return
		
		team_2_turns += 1
		if (team_2_turns >= team_2_players.size()): team_2_turns = 0
		team_2_players[team_2_turns].my_turn = true
		current_player = team_2_players[team_2_turns]
		
	# if current player is team 2, go to next team 1 player
	elif current_player.team == 2  || team_2_players.size() == 0:
		if team_1_players.size() == 0: return
		
		team_1_turns += 1
		if (team_1_turns >= team_1_players.size()): team_1_turns = 0
		team_1_players[team_1_turns].my_turn = true
		current_player = team_1_players[team_1_turns]
	
	set_up_players()
	#turn += 1
	#if (turn >= Lobby.players.size()): turn = 0
	#
	#Lobby.players[turn].my_turn = true
	#current_player = Lobby.players[turn]

@rpc("any_peer", "call_local", "reliable")
func set_up_ball_type(ball_to_hit):
	#var b = dict_to_inst(ball_to_hit)
	current_player.ball_to_hit = ball_to_hit
	
	for player in Lobby.players:
		if current_player.ball_to_hit == 0:
			if player.team == current_player.team:
				player.ball_to_hit = current_player.ball_to_hit
			else:
				player.ball_to_hit = 1 
		else:
			if player.team == current_player.team:
				player.ball_to_hit = current_player.ball_to_hit
			else:
				player.ball_to_hit = 0

@rpc("any_peer", "call_local", "reliable")
func new_game():
	cue_ball_potted = false
	ball_type_chosen = false
	clear_balls()
	generate_balls()
	reset_cue_ball()
	show_cue()
	game_started = true

@rpc("any_peer", "call_local", "reliable")
func connect_pockets():
	table.get_node("Pockets").body_entered.connect(potted_ball)

@rpc("any_peer", "call_local", "reliable")
func clear_balls():
	get_tree().call_group("balls", "queue_free")
	for b in potted:
		b.queue_free()

@rpc("any_peer", "call_local", "reliable")
func generate_balls():
	# setup game balls
	var count : int = 0
	var rows : int = 5
	var dia = 36
	for col in range(5):
		for row in range(rows):
			var b : Ball = ball_scene.instantiate()
			var pos = Vector2(250 + (col * (dia)), 267 + (row * (dia)) + (col * dia / 2))
			add_child(b, true)
			
			# set ball to solid or striped
			if count < 7: b.ball_type = b.Ball_Types.solid
			elif count == 7: b.ball_type = b.Ball_Types.eight_ball
			else: b.ball_type = b.Ball_Types.striped
			
			b.ball_num = count + 1
			b.position = pos
			b.get_node("Sprite2D").texture = ball_images[count]
			count += 1
		rows -= 1

@rpc("any_peer", "call_local", "reliable")
func sleep_ball(ball):
	var b = dict_to_inst(ball)
	b.sleeping = true
	
@rpc("any_peer", "call_local", "reliable")
func remove_cue_ball():
	var old_b = cue_ball
	remove_child(old_b)
	old_b.queue_free()

@rpc("any_peer", "call_local", "reliable")
func reset_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball, true)
	cue_ball.position = START_POS
	cue_ball.get_node("Sprite2D").texture = ball_images.back()
	taking_shot = true
	show_cue()

@rpc("any_peer", "call_local", "reliable")
func scratched():
	placing_cue_ball = true
	cue_ball_placeholder = place_cue_ball_scene.instantiate()
	add_child(cue_ball_placeholder, true)
	cue_ball_placeholder.state = cue_ball_placeholder.States.PLACING
	cue_ball_placeholder.position = START_POS
	cue_ball_placeholder.placed_ball.connect(placed_cue_ball)

@rpc("any_peer", "call_local", "reliable")
func placed_cue_ball(pos):
	#cue_ball.state = cue_ball.States.PLACED
	#remove_cue_ball()
	var old_b = cue_ball_placeholder
	remove_child(old_b)
	old_b.queue_free()
	
	reset_cue_ball()
	cue_ball.position = pos
	show_cue()
	placing_cue_ball = false
	cue_ball_potted = false

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
	#Lobby.players[turn].my_turn = false
	#turn += 1
	#if (turn >= Lobby.players.size()): turn = 0
	#set_up_players()


func potted_ball(body: Ball):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	elif body.ball_type == body.Ball_Types.eight_ball:
		new_game()
	else:
		var b = TextureRect.new()
		var type = body.ball_type
		potted_grid.add_child(b)
		b.texture = body.get_node("Sprite2D").texture
		potted.append(b)
		potted_this_turn.append(type)
		body.queue_free()

func game_over():
	hide_cue()
	get_tree().paused = true
	
