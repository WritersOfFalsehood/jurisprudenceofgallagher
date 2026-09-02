@icon("res://icons/symbols/question-mark-gray.svg")
class_name DialogueChoice
extends DialogueItem

@export var selections : PackedStringArray

func return_choice(choice_index : int):
	get_parent().return_value = choice_index
