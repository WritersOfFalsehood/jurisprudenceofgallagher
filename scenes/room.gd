@icon("res://icons/2d/square-blue.svg")
@tool
extends Node2D
class_name Room


@export var room_size : Vector2:
	set(value):
		room_size = value
		queue_redraw()



@onready var canvas_modulate = $CanvasModulate
@onready var canvas_modulate_background = $Background/CanvasModulateBackground
@onready var camera = $MainCamera
@onready var player = %Gallagher
@onready var left_edge = $LeftEdge
@onready var right_edge = $RightEdge


func _draw():
	if not Engine.is_editor_hint():
		return
	#skip drawing at runtime
	
	draw_rect(Rect2(0, 0, room_size.x, room_size.y), Color.WHITE, false)


func _ready():
	camera.level_top_right.x = room_size.x
	camera.level_bottom_left.y = room_size.y
	
	if PlayerProperties.player_position_in_next_scene.length() != 0:
		player.global_position = PlayerProperties.player_position_in_next_scene
		PlayerProperties.player_position_in_next_scene = Vector2.ZERO
	
	camera.reset_position()
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
