extends Camera2D

@export var use_player_velocity : bool

var following_object

var LERP = 0.15
var LOOK_RATIO = 0.3
var MAX_LOOK_RADIUS = 30

var offset_position : Vector2
var follow_position : Vector2
var target_position : Vector2
var raw_position : Vector2
var view_size : Vector2

var level_top_right : Vector2
var level_bottom_left : Vector2

var original_view_size : Vector2


func _ready():
	original_view_size = get_viewport_rect().size
	view_size.x = get_viewport_rect().size.x / zoom.x
	view_size.y = get_viewport_rect().size.y / zoom.y
	
	#zoom = Vector2.ONE * DisplayManager.pixel_scale


func reset_position():
	raw_position = following_object.position
	target_position = raw_position


func _process(delta):
	view_size.x = get_viewport_rect().size.x / zoom.x
	view_size.y = get_viewport_rect().size.y / zoom.y
	
	follow_position = following_object.position
	target_position = follow_position + offset_position + Vector2.RIGHT * following_object.velocity.x * 0.2 * int(use_player_velocity)
	
	
	
	raw_position = raw_position.lerp(target_position, LERP)
	if (raw_position - target_position).length() < 1:
		raw_position = target_position
	
	
	
	raw_position.x = clamp(raw_position.x, level_bottom_left.x + view_size.x / 2, level_top_right.x - view_size.x / 2)
	raw_position.y = clamp(raw_position.y, level_top_right.y + view_size.y / 2, level_bottom_left.y - view_size.y / 2)
	
	position = raw_position
