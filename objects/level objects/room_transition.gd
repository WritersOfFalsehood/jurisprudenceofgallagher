@icon("res://icons/2d/double-chevron-right-blue.svg")
extends Node2D
class_name RoomTransition


@export_group("Position")
@export var starting_position : Vector2
@export_enum("Right", "Left", "Up", "Down") var direction
@export var size : float		#the "length" of detection in a line 90 degrees counter clockwise from the "direction"

@export_group("Target Room")
@export var target_room_path : String
@export var player_spawner_index : int

const DIRECTION_VECTORS = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN
]

@onready var player : Player = get_tree().current_scene.player

var rect : Rect2
var is_transitioning : bool




func _process(delta):
	var normal_vector = DIRECTION_VECTORS[direction]
	var scalar_vector = starting_position.project(normal_vector)
	var normal_vector_rotated = normal_vector.rotated(PI/2)
	var scalar_vector_rotated = starting_position.project(normal_vector_rotated)
	
	var distance_from_line = normal_vector.dot(player.global_position) - scalar_vector.length() * sign(normal_vector.x + normal_vector.y)
	var distance_from_origin = normal_vector_rotated.dot(player.global_position) - scalar_vector_rotated.length() * sign(normal_vector_rotated.x + normal_vector_rotated.y)
	#used to check whether player is in line with the length of the detection line, comes out negative
	
	if distance_from_line > 0 and distance_from_origin < 0 and distance_from_origin > -size and !get_tree().current_scene.room_transitioner.is_transitioning:
		player.current_transition_direction = DIRECTION_VECTORS[direction]
		get_tree().current_scene.room_transitioner.transition(target_room_path, player_spawner_index)
