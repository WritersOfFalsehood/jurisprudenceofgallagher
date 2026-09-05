extends Event

@export var movements : Array[ForcedPlayerMovement]

@onready var player = get_tree().current_scene.player


func execute_movement(index : int):
	var action = movements[index].input_action
	if action != "Move to Point":
		player.simulated_inputs[action] = true
		await get_tree().create_timer(movements[index].duration).timeout
		player.simulated_inputs[action] = false
	else:
		# 'duration' now denotes the relative coordinate of the horizontal point to stop at
		# dont run if too close to point
		var target_point = global_position + Vector2.RIGHT * movements[index].duration
		
		if abs(player.global_position.x - target_point.x) > 1.0:
			var direction = sign(target_point.x - player.global_position.x)
			var new_action = "Left" if direction == -1 else "Right"
			player.simulated_inputs[new_action] = true
			
			while abs(player.global_position.x - target_point.x) > 1.0 and sign(target_point.x - player.global_position.x) == direction:
				await get_tree().physics_frame
				
			player.simulated_inputs[new_action] = false
		
		player.global_position.x = target_point.x
		player.velocity = Vector2.ZERO + Vector2.DOWN * player.velocity.y


func on_execute():
	player.ignore_player_input = true
	
	var index : int = 0
	for i in movements:
		await execute_movement(index)
		await get_tree().create_timer(movements[index].time_to_next_input).timeout
		index += 1
	finish()


func on_finish():
	for action in player.simulated_inputs:
		action = false
	player.ignore_player_input = false
