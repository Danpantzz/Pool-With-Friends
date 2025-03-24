extends Control

var cue_images: Array = []
var cloth_images: Array = []

var cue_index := 0
var cloth_index := 0

@onready var address_entry: LineEdit = %AddressEntry
@onready var main_menu: Control = %MainMenu
@onready var lobby: Control = %Lobby
@onready var customize: Control = %Customize
@onready var list_1: VBoxContainer = %List1
@onready var list_2: VBoxContainer = %List2
@onready var start_button: Button = %StartButton
@onready var main: Control = %Main
@onready var join_menu: Control = %JoinMenu

@onready var cloth_texture: TextureRect = %ClothTexture
@onready var cue_texture: TextureRect = %CueTexture

func _ready() -> void:
	# set up array of cue images
	load_images(cue_images, "res://assets/cues/")
	#print(cue_images)
	# set up array of cloth images
	
	
	main_menu.show()
	main.show()
	join_menu.hide()
	lobby.hide()
	
	Lobby.player_connected.connect(change_ui)
	Lobby.team_changed.connect(display_teams)
	
func _process(delta: float) -> void:
	pass

# iterate through directory, append files to array
func load_images(array, path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				#print("Found directory: " + file_name)
				pass
			elif file_name.contains(".import"):
				pass
			else:
				#print("Found file: " + file_name)
				
				# add file to array
				array.append(path + file_name)
				
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func _on_host_pressed() -> void:
	Lobby.create_game()

func _on_join_pressed() -> void:
	main.hide()
	join_menu.show()

func _on_join_back_button_pressed() -> void:
	join_menu.hide()
	main.show()

func _on_prev_cloth_pressed() -> void:
	pass # Replace with function body.

func _on_next_cloth_pressed() -> void:
	pass # Replace with function body.

# iterate backwards through cue_images
func _on_prev_cue_pressed() -> void:
	cue_index -= 1
	if cue_index < 0: cue_index = cue_images.size() - 1
	cue_texture.texture = load(cue_images[cue_index])
	Lobby.player_info.cue_image = cue_images[cue_index]

# iterate forward through cue_images
func _on_next_cue_pressed() -> void:
	cue_index += 1
	if cue_index >= cue_images.size(): cue_index = 0
	cue_texture.texture = load(cue_images[cue_index])
	Lobby.player_info.cue_image = cue_images[cue_index]

func _on_customize_pressed() -> void:
	main_menu.hide()
	customize.show()

func _on_customize_back_button_pressed() -> void:
	customize.hide()
	main_menu.show()

func _on_connect_pressed() -> void:
	Lobby.join_game(address_entry.text)

func change_ui(id, info):
	if not multiplayer.is_server(): start_button.disabled = true
	main_menu.hide()
	lobby.show()
	display_teams()

func display_teams():
	# remove all team names
	for c in list_1.get_children():
		c.queue_free()
	for c in list_2.get_children():
		c.queue_free()
	
	# create player lists
	for player in Lobby.players:
		print(player)
		if player.team == 1:
			var name = Label.new()
			list_1.add_child(name)
			name.text = player.name
		elif player.team == 2:
			var name = Label.new()
			list_2.add_child(name)
			name.text = player.name
			

func _on_name_entry_text_changed(new_text: String) -> void:
	Lobby.player_info.name = new_text

func _on_team_1_button_pressed() -> void:
	Lobby.change_team.rpc(1)


func _on_team_2_button_pressed() -> void:
	Lobby.change_team.rpc(2)


func _on_start_button_pressed() -> void:
	Lobby.load_game.rpc("res://scenes/main.tscn")
	#get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_color_picker_button_color_changed(color: Color) -> void:
	cloth_texture.modulate = color
