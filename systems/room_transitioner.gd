extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var is_transitioning : bool


func _ready() -> void:
	color_rect.color.a = 0


func transition(target_room_path : String, player_spawner_index : int):
	is_transitioning = true
	
	var target_room_packed : PackedScene = load(target_room_path)
	
	# fade to black
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(color_rect, "color:a", 1, 0.5)
	await fade_in_tween.finished
	
	get_tree().current_scene.load_room(target_room_path, player_spawner_index)
	
	# fade out of black
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(color_rect, "color:a", 0, 0.5)
	await fade_out_tween.finished
	
	is_transitioning = false
