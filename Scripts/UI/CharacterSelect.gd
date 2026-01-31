extends Control

@onready var container = $VBoxContainer/GridContainer
@onready var label = $VBoxContainer/Label

var selecting_player = 1

func _ready():
	label.text = "Player 1 Select Character"
	_create_buttons()

func _create_buttons():
	for char_name in Global.character_list.keys():
		var btn = Button.new()
		btn.text = char_name
		btn.custom_minimum_size = Vector2(200, 60)
		btn.pressed.connect(_on_character_selected.bind(char_name))
		container.add_child(btn)

func _on_character_selected(char_name: String):
	var data = Global.get_character_data(char_name)
	
	if selecting_player == 1:
		Global.p1_data = data
		selecting_player = 2
		label.text = "Player 2 Select Character"
	else:
		Global.p2_data = data
		_start_game()

func _start_game():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
