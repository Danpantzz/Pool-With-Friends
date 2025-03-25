extends Control

#@export var menu_scene: PackedScene

var cue_images: Array = []
var cloth_images: Array = []

var cue_index := 0
var cloth_index := 0

@onready var cloth_texture: TextureRect = %ClothTexture
@onready var cushions_texture: TextureRect = %CushionsTexture
@onready var cue_texture: TextureRect = %CueTexture

@onready var cloth_color_picker: ColorPickerButton = %ClothColorPicker
@onready var cushions_color_picker: ColorPickerButton = %CushionsColorPicker
@onready var check_button: CheckButton = %CheckButton

func _ready() -> void:
	# set up array of cue images
	load_images(cue_images, "res://assets/cues/")
	#print(cue_images)
	# set up array of cloth images
	
	cloth_texture.modulate = Lobby.player_info.cloth_color
	cloth_color_picker.color = Lobby.player_info.cloth_color
	cushions_texture.modulate = Lobby.player_info.cushion_color
	cushions_color_picker.color = Lobby.player_info.cushion_color
	
	check_button.button_pressed = Lobby.player_info.show_player_tables

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

func _on_customize_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_cloth_color_picker_color_changed(color: Color) -> void:
	cloth_texture.modulate = color
	#cloth.modulate = color
	Lobby.player_info.cloth_color = color

func _on_cushions_color_picker_color_changed(color: Color) -> void:
	cushions_texture.modulate = color
	#cushions.modulate = color
	Lobby.player_info.cushion_color = color


func _on_check_button_toggled(toggled_on: bool) -> void:
	Lobby.player_info.show_player_tables = toggled_on
