extends Node2D

var player_object

var hp : int
var max_hp : int = 5

var gold : int
var max_gold : int = 9999999999

var is_talking : bool

#for managing player position while screen transitioning
var player_position_in_next_scene : Vector2
var player_direction_in_next_scene : int


func _ready():
	hp = max_hp


func _process(delta: float) -> void:
	hp = min(hp, max_hp)
	gold = min(gold, max_gold)
