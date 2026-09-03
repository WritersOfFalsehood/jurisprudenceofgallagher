@icon("res://icons/2d/spark-full-yellow.svg")
class_name Event
extends Node2D

@export var enabled : bool = true
var active : bool
var is_executed_in_this_run : bool

signal on_event_executed
signal on_event_finished


func execute():
	if enabled:
		if !active:
			on_execute()
			
			active = true
			get_parent().event_started(self)
			on_event_executed.emit()
	else:
		finish()


func finish():
	on_finish()
	
	is_executed_in_this_run = true
	active = false
	get_parent().event_ended(self)
	if enabled:
		on_event_finished.emit()


func on_execute():
	pass


func on_finish():
	pass
