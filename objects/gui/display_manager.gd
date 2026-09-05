extends Node

@onready var window = get_window()

var camera : Camera2D
var hud : CanvasLayer
var dialogue_system : CanvasLayer

var is_fullscreen : bool


func _input(event):
	if event.is_action_pressed("Fullscreen"):
		is_fullscreen = !is_fullscreen
		if is_fullscreen:
			window.set_deferred("mode", Window.MODE_FULLSCREEN)
		else:
			window.set_deferred("mode", Window.MODE_WINDOWED)
		
