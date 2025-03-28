extends Resource

class_name Player_Info

var _id: int
var name: String = "Player"
var team: int = 1
var my_turn: bool = false
var ball_to_hit: Ball.Ball_Types = -1
var show_player_tables: bool = true
var cloth_color := Color("2eaa30")
var cushion_color:= Color("5aa02c")
#var cue_image := ("res://assets/cues/cue.png")
var cue_image := "res://scenes/cues/cue_default.tscn"
var cloth_image : PackedByteArray
