@icon("res://icons/objects/magnifying-glass-gray.svg")
class_name DialogueItem
extends Node

@export var enabled : bool = true
@export var character_name : String
@export var portrait : CompressedTexture2D
@export_multiline var character_text : String

var active : bool

signal dialogue_item_activated
signal dialogue_item_deactivated


func activate():
	if enabled:
		active = true
		get_tree().current_scene.dialogue_box.initialise(self)
		
		dialogue_item_activated.emit()
	else:
		deactivate()
	
func deactivate():
	active = false
	get_parent().next_item()
	
	dialogue_item_deactivated.emit()
