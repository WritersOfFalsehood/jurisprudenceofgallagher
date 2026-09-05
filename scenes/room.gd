@icon("res://icons/2d/square-blue.svg")
@tool
extends Node2D
class_name Room


@export var room_size : Vector2:
	set(value):
		room_size = value
		queue_redraw()

var player : Player

@onready var canvas_modulate = $CanvasModulate
@onready var camera = $MainCamera
@onready var tile_map: Node2D = $TileMap
@onready var enemies: Node2D = $Enemies
@onready var objects: Node2D = $Objects
@onready var projectiles: Node2D = $Projectiles
@onready var room_transitions: Node2D = $RoomTransitions
@onready var loot: Node2D = $Loot
@onready var particles: Node2D = $Particles
@onready var player_spawn_points: Node2D = $PlayerSpawnPoints



func _draw():
	if not Engine.is_editor_hint():
		return
	#skip drawing at runtime
	
	draw_rect(Rect2(0, 0, room_size.x, room_size.y), Color.WHITE, false)


func _ready():
	camera.level_top_right.x = room_size.x
	camera.level_bottom_left.y = room_size.y
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
