@icon("res://icons/symbols/todo-yellow.svg")
class_name InteractionObject
extends Node

@onready var interact_sign = $InteractSign
@onready var interaction_manager = get_tree().current_scene.systems.interaction_manager
@onready var player = get_tree().current_scene.player

@export_enum("Manuel", "Manuel Only Grounded", "Instant", "Disabled") var interaction_mode : int
@export var automatically_continue : bool = true
@export var reroll_after_finish : bool = true
@export var show_interact_sign : bool
@export var interact_sign_height : float

var events : Array
var events_active : bool
var index = 0

signal on_event_start(event)
signal on_event_end(event)

signal on_events_start
signal on_events_end

# Called when the node enters the scene tree for the first time.
func _ready():
	interact_sign.visible = false
	
	for child in get_children():
		if child is Event:
			events.append(child)


func _process(delta):
	interact_sign.position.y = -interact_sign_height
	interact_sign.visible = interaction_manager.current_interaction_object == self and show_interact_sign and !(interaction_mode == 1 and !player.is_on_floor()) and player.can_move


func add_this_interaction(area):
	if interaction_mode == 0 or interaction_mode == 1:
		interaction_manager.add_interaction(self)
	else:
		execute_event()


func remove_this_interaction(area):
	if interaction_mode == 0 or interaction_mode == 1:
		interaction_manager.remove_interaction(self)


func execute_event():
	if index < events.size():
		events_active = true
		
		if !events[index].is_executed_in_this_run:
			events[index].execute()
			
	elif reroll_after_finish:
		reset_list()
		if !automatically_continue:
			execute_event()
	else:
		index = events.size() - 1
		events[index].is_executed_in_this_run = false
		if !automatically_continue:
			execute_event()


func reset_list():
	events_active = false
	index = 0
	for event in events:
		event.is_executed_in_this_run = false


func event_started(event):
	on_event_start.emit(event)
	if index == 0:
		on_events_start.emit()


func event_ended(event):
	if event.enabled:
		on_event_end.emit(event)
	
	index += 1
	if index == events.size():
		on_events_end.emit()
	
	if automatically_continue:
		execute_event()
	else:
		events_active = false
