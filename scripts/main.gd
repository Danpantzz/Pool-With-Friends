extends Node

@export var ball_scene : PackedScene

@onready var main_menu: PanelContainer = $CanvasLayer/MainMenu

@onready var table: Sprite2D = %Table
@onready var cue: Sprite2D = %Cue
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
var game_started := false

# multiplayer variables
const PORT = 9999
var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene

@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var address_entry: LineEdit = %AddressEntry

func _ready() -> void:
	load_images()
	#new_game()
	table.get_node("Pockets").body_entered.connect(potted_ball)
	
func load_images():
	for i in range(1, 17, 1):
		var filename = str("res://assets/balls/ball_", i, ".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)
	
func new_game():
	generate_balls()
	reset_cue_ball()
	show_cue()
	game_started = true
	
func generate_balls():
	# setup game balls
	var count : int = 0
	var rows : int = 5
	var dia = 36
	for col in range(5):
		for row in range(rows):
			var b = ball_scene.instantiate()
			var pos = Vector2(250 + (col * (dia)), 267 + (row * (dia)) + (col * dia / 2))
			add_child(b)
			
			# set ball to solid or striped
			if count <= 7: b.solid = true
			elif count == 9: b.eight_ball = true
			else: b.solid = false
			
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
	
func show_cue():
	cue.set_physics_process(true)
	cue.position = cue_ball.position
	power_bar.position.x = cue_ball.position.x - (0.5 * power_bar.size.x)
	power_bar.position.y = cue_ball.position.y + power_bar.size.y
	cue.show()
	power_bar.show()

func hide_cue():
	cue.set_physics_process(false)
	cue.hide()
	power_bar.hide()
	
func _process(_delta) -> void:
	if not game_started: return
	
	var moving := false
	
	# check that all balls have stopped moving
	for b in get_tree().get_nodes_in_group("balls"):
		if (b.linear_velocity.length() > 0.0 and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
			
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
	
	if not moving:
		# check if cue ball has been potted and reset it
		if cue_ball_potted:
			reset_cue_ball()
			cue_ball_potted = false
		
		if not taking_shot:
			print("here")
			taking_shot = true
			show_cue()
	else:
		if taking_shot:
			taking_shot = false
			hide_cue()

func _on_cue_shoot(power) -> void:
	cue_ball.apply_central_impulse(power)
	
func potted_ball(body):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	else:
		var b = TextureRect.new()
		potted_grid.add_child(b)
		b.texture = body.get_node("Sprite2D").texture
		potted.append(b)
		body.queue_free()

# Multiplayer Logic
func _on_host_pressed() -> void:
	main_menu.hide()
	
	# Set up multiplayer peer
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# add player to scene
	add_player(multiplayer.get_unique_id())
	
	# set up upnp server
	upnp_setup()

func _on_join_pressed() -> void:
	if address_entry.text == "": return
	
	main_menu.hide()
	
	peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = peer

func add_player(peer_id):
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	add_child(player)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	
func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
		
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
