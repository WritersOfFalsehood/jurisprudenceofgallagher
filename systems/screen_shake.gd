extends Node

var noise_shake_speed: float = 30.0
var noise_shake_strength: float = 60.0
var shake_decay_rate: float = 5.0

@onready var noise = FastNoiseLite.new()

var noise_i : float
var current_shake_strength : float


func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.frequency = 0.5


func _process(delta: float) -> void:
	current_shake_strength = lerpf(current_shake_strength, 0, shake_decay_rate * delta)
	if get_tree().current_scene.current_room is Room:
		get_tree().current_scene.current_room.camera.offset = get_noise_offset(delta)


func screen_shake(shake_strength : float, shake_speed : float, shake_decay : float):
	noise_shake_strength = shake_strength
	noise_shake_speed = shake_speed
	shake_decay_rate = shake_decay
	
	current_shake_strength = noise_shake_strength


func get_noise_offset(delta : float):
	var camera = get_tree().current_scene.current_room.camera
	
	noise_i += delta * noise_shake_speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	var initial_offset = Vector2(noise.get_noise_2d(1, noise_i), noise.get_noise_2d(100, noise_i)) * current_shake_strength
	
	var final_position = camera.global_position + initial_offset
	var clamped_view_pos := Vector2(
		clampf(final_position.x, camera.level_bottom_left.x + camera.view_size.x / 2, camera.level_top_right.x - camera.view_size.x / 2),
		clampf(final_position.y, camera.level_top_right.y + camera.view_size.y / 2, camera.level_bottom_left.y - camera.view_size.y / 2)
	)
	return clamped_view_pos - camera.global_position
