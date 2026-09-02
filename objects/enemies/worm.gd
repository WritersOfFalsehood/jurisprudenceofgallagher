extends Enemy


@export var walk_speed : float


func _physics_process(delta: float) -> void:
	sprite.play()
	sprite.flip_h = direction != 1
	
	if is_getting_knockbacked:
		move_velocity = Vector2.ZERO
	
	if is_on_wall():
		direction *= -1
	
	move_velocity = Vector2.RIGHT * walk_speed * direction
	
	#dont wander off edges
	if turn_on_edge and is_on_floor():
		if !edge_detector_left.has_overlapping_bodies():
			direction = 1
		if !edge_detector_right.has_overlapping_bodies():
			direction = -1
	
	super._physics_process(delta)
