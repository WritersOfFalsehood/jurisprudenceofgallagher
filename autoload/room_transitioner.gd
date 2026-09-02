extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var is_transitioning : bool


const DIRECTION_VECTORS = [
	Vector2.RIGHT,
	Vector2.LEFT,
	Vector2.UP,
	Vector2.DOWN
]


func _ready() -> void:
	color_rect.color.a = 0


func _process(delta: float) -> void:
	pass


func transition(target_player_position : Vector2, target_room_path : String, direction):
	is_transitioning = true
	PlayerProperties.player_object.current_transition_direction = DIRECTION_VECTORS[direction]
	
	var target_room_packed : PackedScene = load(target_room_path)
	var new_player_position = target_player_position
	
	PlayerProperties.player_position_in_next_scene = new_player_position
	if direction < 2:
		PlayerProperties.player_direction_in_next_scene = sign(DIRECTION_VECTORS[direction].x + DIRECTION_VECTORS[direction].y)
	
	# fade to black
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color:a", 1, 0.5)
	await fade_in_tween.finished
	
	get_tree().change_scene_to_packed(target_room_packed)
	PlayerProperties.player_object.current_transition_direction = Vector2.ZERO
	
	# fade out of black
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color:a", 0, 0.5)
	await fade_out_tween.finished
	
	is_transitioning = false
