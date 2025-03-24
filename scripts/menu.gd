extends Control

@export var customize_scene: PackedScene

@onready var address_entry: LineEdit = %AddressEntry
@onready var main_menu: Control = %MainMenu
@onready var lobby: Control = %Lobby
@onready var list_1: VBoxContainer = %List1
@onready var list_2: VBoxContainer = %List2
@onready var start_button: Button = %StartButton
@onready var main: Control = %Main
@onready var join_menu: Control = %JoinMenu
@onready var cloth: TextureRect = %Cloth
@onready var cushions: TextureRect = %Cushions

func _ready() -> void:
	
	cloth.modulate = Lobby.player_info.cloth_color
	cushions.modulate = Lobby.player_info.cushion_color
	
	main_menu.show()
	main.show()
	join_menu.hide()
	lobby.hide()
	
	Lobby.player_connected.connect(change_ui)
	Lobby.team_changed.connect(display_teams)
	
func _process(delta: float) -> void:
	pass

func _on_host_pressed() -> void:
	Lobby.create_game()

func _on_join_pressed() -> void:
	main.hide()
	join_menu.show()

func _on_join_back_button_pressed() -> void:
	join_menu.hide()
	main.show()

func _on_customize_pressed() -> void:
	get_tree().change_scene_to_packed(customize_scene)

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
