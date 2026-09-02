extends Enemy


@export var walk_speed : float
@export var dash_speed : float
@export var dash_range : float
@export var alert_jump_speed : float

@onready var follow_object = PlayerProperties.player_object

var ai_state : int

func _physics_process(delta):
	if is_getting_knockbacked:
		move_velocity = Vector2.ZERO
		ai_state = -1
		
		direction = -sign(velocity.x)
		if direction == 0:
			direction = 1
		sprite.play("knockback")
	
	if is_stunned:
		move_velocity = Vector2.ZERO
		ai_state = -2
	
	match ai_state:
		# getting stunned
		-2:
			if !is_stunned:
				ai_state = 0
		
		# getting knockbacked
		-1:
			if !is_getting_knockbacked:
				ai_state = 0
		
		# walking
		0:
			if is_on_wall():
				direction *= -1
			
			#dont wander off edges
			if turn_on_edge and is_on_floor():
				if !edge_detector_left.has_overlapping_bodies():
					direction = 1
				if !edge_detector_right.has_overlapping_bodies():
					direction = -1
			
			move_velocity = Vector2.RIGHT * direction * walk_speed
			
			sprite.play("walk")
			
			if global_position.distance_to(follow_object.global_position) <= dash_range:
				# start dashing
				direction = sign(follow_object.global_position.x - global_position.x)
				if direction == 0:
					direction = 1
				velocity.y = -alert_jump_speed
				ai_state = 1
		# dashing
		1:
			if is_on_wall():
				apply_knockback(direction * -1, 100)
				# stop dashing
				ai_state = 0
			
			move_velocity = Vector2.RIGHT * direction * dash_speed
			
			sprite.play("run")
	
	sprite.flip_h = direction != 1
	
	
	super._physics_process(delta)
	
	
