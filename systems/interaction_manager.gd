extends Node

var interaction_list : Array
var current_interaction_object : InteractionObject


func _process(delta):
	if interaction_list.size() > 0:
		current_interaction_object = interaction_list[max(0, interaction_list.size() - 1)]
	else:
		current_interaction_object = null


func _input(event):
	if event.is_action_pressed("Interact") and get_tree().current_scene.player.can_move:
		interact()


func add_interaction(interaction_object):
	interaction_list.append(interaction_object)


func remove_interaction(interaction_object):
	interaction_list.erase(interaction_object)


func interact():
	if (interaction_list.size() > 0):
		if !current_interaction_object.events_active:
			if current_interaction_object.interaction_mode == 1:
				if get_tree().current_scene.player.is_on_floor():
					current_interaction_object.execute_event()
			else:
				current_interaction_object.execute_event()
