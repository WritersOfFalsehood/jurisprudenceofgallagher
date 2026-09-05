extends Event

@onready var player = get_tree().current_scene.player

func on_execute():
	player.direction_x = 1
	player.is_sitting = true
	get_tree().current_scene.systems.player_properties.hp = get_tree().current_scene.systems.player_properties.max_hp
	await get_tree().process_frame
	finish()
