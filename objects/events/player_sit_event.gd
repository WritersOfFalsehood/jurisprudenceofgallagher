extends Event

@onready var player = PlayerProperties.player_object

func on_execute():
	player.direction_x = 1
	player.is_sitting = true
	PlayerProperties.hp = PlayerProperties.max_hp
	await get_tree().process_frame
	finish()
