extends Control

@onready var address_entry: LineEdit = %AddressEntry
@onready var main_menu: Panel = $MainMenu
@onready var lobby: Panel = $Lobby
@onready var list_1: VBoxContainer = %List1
@onready var list_2: VBoxContainer = %List2
@onready var start_button: Button = %StartButton

func _ready() -> void:
	#if not multiplayer.is_server(): start_button.disabled
	
	Lobby.player_connected.connect(change_ui)
	Lobby.team_changed.connect(display_teams)
	
func _process(delta: float) -> void:
	pass

func _on_host_pressed() -> void:
	Lobby.create_game()

func _on_join_pressed() -> void:
	Lobby.join_game(address_entry.text)

func change_ui(id, info):
	if not multiplayer.get_unique_id() == 1: start_button.disabled = true
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
		if player.team == 0:
			var name = Label.new()
			list_1.add_child(name)
			name.text = player.name
		elif player.team == 1:
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
