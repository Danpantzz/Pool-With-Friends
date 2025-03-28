extends Control

#@export var menu_scene: PackedScene

var cue_images: Array = []
var cloth_images: Array = []

var cue_index := 0
var cloth_index := 0
var cue_on_display

@onready var file_dialog: FileDialog = %FileDialog
@onready var case: Panel = %Case

@onready var cloth_texture: TextureRect = %ClothTexture
@onready var cushions_texture: TextureRect = %CushionsTexture
#@onready var cue_texture: TextureRect = %CueTexture

@onready var cloth_color_picker: ColorPickerButton = %ClothColorPicker
@onready var cushions_color_picker: ColorPickerButton = %CushionsColorPicker
@onready var check_button: CheckButton = %CheckButton

func _ready() -> void:
	# set up array of cue images
	load_images(cue_images, "res://scenes/cues/")
	
	cue_on_display = case.get_child(0)
	# set up array of cloth images
	#load_images(cloth_images, "res://assets/cloths/")
	
	if Lobby.player_info.cloth_image:
		#var image_texture = ImageTexture.new()
		#image_texture.set_image(Lobby.player_info.cloth_image)
		#image_texture.set_size_override(Vector2(1100, 580))
		cloth_texture.texture = Helpers.load_image_from_buffer(Lobby.player_info.cloth_image)
	
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
				var cue = (path + file_name)
				# add file to array
				array.append(cue)
				
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
	#cue_texture.texture = load(cue_images[cue_index])
	if (cue_on_display):
		case.remove_child(cue_on_display)
	cue_on_display = load(cue_images[cue_index]).instantiate()
	case.add_child(cue_on_display)
	cue_on_display.position = Vector2(890, 45)
	
	Lobby.player_info.cue_image = cue_images[cue_index]

# iterate forward through cue_images
func _on_next_cue_pressed() -> void:
	cue_index += 1
	if cue_index >= cue_images.size(): cue_index = 0
	#cue_texture.texture = load(cue_images[cue_index])
	if (cue_on_display):
		case.remove_child(cue_on_display)
	cue_on_display = load(cue_images[cue_index]).instantiate()
	case.add_child(cue_on_display)
	cue_on_display.position = Vector2(890, 45)
	
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

func _on_choose_file_pressed() -> void:
	file_dialog.popup()

func _on_file_dialog_file_selected(path: String) -> void:
	#Lobby.player_info.cloth_image = path
	
	#var image = Image.new()
	#image.load(path)
	#image.save_png("res://assets/cloths/%s_cloth" % Lobby.player_info._id)
	#Lobby.player_info.cloth_image = image
	
	#var image_texture = ImageTexture.new()
	#image_texture.set_image(image)
	#image_texture.set_size_override(Vector2(1100, 580))
	cloth_texture.texture = load_image(path)
	
	cloth_color_picker.color = Color.WHITE
	cloth_texture.modulate = Color.WHITE
	Lobby.player_info.cloth_color = Color.WHITE

func load_image(path: String):
	if path.begins_with('res'):
		return load(path)
	else:
		var file = FileAccess.open(path, FileAccess.READ)
		if FileAccess.get_open_error() != OK:
			print(str("Could not load image at: ",path))
			return
		var buffer = file.get_buffer(file.get_length())
		
		Lobby.player_info.cloth_image = buffer
		
		var image = Image.new()
		var error = image.load_png_from_buffer(buffer)
		if error != OK:
			print(str("Could not load image at: ",path," with error: ",error))
			return
		var texture = ImageTexture.new()
		texture.set_image(image)
		texture.set_size_override(Vector2(1100, 580))
		return texture
