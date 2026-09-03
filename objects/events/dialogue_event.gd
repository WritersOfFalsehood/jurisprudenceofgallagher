@icon("res://icons/objects/magnifying-glass-yellow.svg")
extends Event

@export var event_chains : Array[InteractionObject]

var dialogue_items : Array[DialogueItem]
var index = 0

var return_value : int = -1


func _ready():
	for child in get_children():
		if child is DialogueItem:
			dialogue_items.append(child)
	
	if dialogue_items.size() <= 0:
		enabled = false


func on_execute():
	DialogueBox.visible = true
	dialogue_items[index].activate()


func on_finish():
	DialogueBox.visible = false
	index = 0
	
	if enabled:
		if event_chains.size() > 0:
			if return_value < event_chains.size() and return_value > -1:
				event_chains[return_value].execute_event()
	


func next_item():
	index += 1
	if index < dialogue_items.size():
		dialogue_items[index].activate()
	else:
		finish()
