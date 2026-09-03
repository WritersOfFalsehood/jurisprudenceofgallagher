@icon("res://icons/objects/chest-yellow.svg")
extends Resource
class_name Loot

@export var item : PackedScene
## Selects between the minimum and maximum values (inclusive) randomly
## Set to below 0 to increase the chances of not spawning
@export var amount_min : int
## Selects between the minimum and maximum values (inclusive) randomly
@export var amount_max : int
