extends Node

# Autoload named Lobby

#These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal team_changed()

const PORT = 9999
const DEFAULT_SERVER_IP = "localhost" # IPv4 localhost
const MAX_CONNECTIONS = 20

var join_address = ""

var peer = ENetMultiplayerPeer.new()

# This will contain player info for every player,
# with the keys being each player's unique IDs.

var players: Array[Player_Info] = []

#var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.

var player_info: Player_Info = Player_Info.new()

#var player_info = {
	#"name": "Name",
	#"team": 1,
	#"ball_type": Ball.Ball_Types.solid
	#}

var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	#var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

func create_game():
	#var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	
	player_info._id = 1
	players.append(player_info)
	#players[1] = player_info
	
	#players[1] = player_info
	player_connected.emit(1, player_info)
	
	upnp_setup()

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	players.clear()

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	
	# convert images to rawdata
	#var cue_texture = load(player_info.cue_image) as ImageTexture
	#var cue_image = cue_texture.get_data()
	#var cue_data = cue_image.get_data()
	#
	#var cloth_data
	#if player_info.cloth_image:
		#var cloth_image := player_info.cloth_image
		#cloth_data = cloth_image.get_data()
	
	# encrypt data
	var info = inst_to_dict(player_info)
	
	_register_player.rpc_id(id, info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	# decrypt data
	var info = dict_to_inst(new_player_info)
	
	#if cloth_data:
		#var cloth_image = Image.new()
		#var cloth_image_error = cloth_image.load_png_from_buffer(cloth_data)
		#if cloth_image_error != OK:
			#push_error("An error occurred while trying to display the image.")
		##var cloth_texture = ImageTexture.new()
		##cloth_texture.create_from_image(cloth_image)
		##
		#info.cloth_image = cloth_image
	
	var new_player_id = multiplayer.get_remote_sender_id()
	#players[new_player_id] = info
	
	players.append(info)
	
	players.sort_custom(my_sort)
	player_connected.emit(new_player_id, info)

func my_sort(a, b):
	if a._id > b._id: return true
	return false

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	#players[peer_id] = player_info
	
	player_info._id = peer_id
	players.append(player_info)
	
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

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
	join_address = upnp.query_external_address()

@rpc("any_peer", "call_local", "reliable")
func change_team(team):
	for player in players:
		if player._id == multiplayer.get_remote_sender_id():
			player.team = team
			break
	#players[multiplayer.get_remote_sender_id()].team = team
	#print(players)
	team_changed.emit()
