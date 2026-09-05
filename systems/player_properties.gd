extends Node

var hp : int
var max_hp : int = 5

var gold : int
var max_gold : int = 9999999999


func _ready():
	hp = max_hp


func _process(delta: float) -> void:
	hp = min(hp, max_hp)
	gold = min(gold, max_gold)
