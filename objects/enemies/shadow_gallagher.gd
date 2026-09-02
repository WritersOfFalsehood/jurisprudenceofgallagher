extends Enemy

@export var wander_speed : float
@export var follow_speed : float
@export var engage_range : float
@export var disengage_range : float
@export var attack_range : float
@export var attack_onset : float
@export var attack_action : float
@export var attack_decay : float


@onready var ai_state_timer = $AIStateTimer
@onready var attack_timer = $AttackTimer
@onready var attack_cooldown_timer = $AttackCooldownTimer
@onready var side_attack = $SideAttack
@onready var up_attack = $UpAttack

@onready var follow_object = PlayerProperties.player_object

var ai_state : int

enum attack_types {
	SIDE_ATTACK,
	UP_ATTACK,
}

var attack_type : int

var attack_stage : int
# 0 = not attacking, 1 = onset, 2 = action, 3 = decay


func _physics_process(delta):
	
	if is_getting_knockbacked:
		ai_state_timer.stop()
		attack_timer.stop()
		move_velocity = Vector2.ZERO
		ai_state = -1
		
		direction = -sign(velocity.x)
		if direction == 0:
			direction = 1
		sprite.play("fall")
	
	if is_stunned:
		ai_state_timer.stop()
		attack_timer.stop()
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
		
		# waiting
		0:
			sprite.play("idle")
			move_velocity = Vector2.ZERO
			
			if ai_state_timer.is_stopped():
				#time spent wandering
				ai_state_timer.start(randf_range(1.5, 2.5))
				direction = randi_range(0, 1) * 2 - 1
				
				#switch to wandering
				ai_state = 1
			
			if global_position.distance_to(follow_object.global_position) <= engage_range:
				#switch to following
				ai_state = 2
		
		# wandering
		1:
			if is_on_wall():
				direction *= -1
			
			#dont wander off edges
			if turn_on_edge and is_on_floor():
				if !edge_detector_left.has_overlapping_bodies():
					direction = 1
				if !edge_detector_right.has_overlapping_bodies():
					direction = -1
			
			move_velocity = Vector2.RIGHT * direction * wander_speed
			
			if velocity.y > 0:
				sprite.play("fall")
			elif velocity.y < 0:
				sprite.play("jump")
			elif abs(velocity.x) != 0:
				sprite.play("walk")
			else:
				sprite.play("idle")
			
			if ai_state_timer.is_stopped():
				#time spent waiting
				ai_state_timer.start(randf_range(0.3, 2))
				
				#switch to waiting
				ai_state = 0
			
			if global_position.distance_to(follow_object.global_position) <= engage_range:
				#switch to following
				ai_state = 2
		
		# following
		2:
			direction = sign(follow_object.global_position.x - global_position.x)
			if direction == 0:
				direction = 1
			
			if velocity.y > 0:
				sprite.play("fall")
			elif velocity.y < 0:
				sprite.play("jump")
			elif abs(velocity.x) != 0:
				sprite.play("walk")
			else:
				sprite.play("idle")
				
			move_velocity = Vector2.RIGHT * direction * follow_speed
			
			#dont run over edges while chasing player
			if !follow_beyond_edge and is_on_floor():
				if !edge_detector_left.has_overlapping_bodies() and direction == -1:
					move_velocity = Vector2.ZERO
				if !edge_detector_right.has_overlapping_bodies() and direction == 1:
					move_velocity = Vector2.ZERO
			
			
			if global_position.distance_to(follow_object.global_position) >= disengage_range:
				#switch to waiting
				ai_state = 0
			
			if global_position.distance_to(follow_object.global_position) <= attack_range:
				if attack_cooldown_timer.is_stopped():
					#begin attack
					ai_state = 3
					attack_stage = 1
					attack_timer.start(attack_onset)
					sprite.play("attack 1")
		
		#attack
		3:
			move_velocity = Vector2.ZERO
			
			if attack_stage == 0:
				#switch to waiting
				ai_state = 0
				#cooldown time
				attack_cooldown_timer.start(0.7)
	
	side_attack.scale.x = direction
	
	side_attack.collision_shape.disabled = attack_stage != 2
	
	# bandaid fix until i implement up attacking
	up_attack.collision_shape.disabled = true
	
	sprite.flip_h = direction != 1
	
	
	super._physics_process(delta)


func _on_attack_timer_timeout():
	match attack_stage:
		1:
			# Onset ends
			attack_timer.start(attack_action)
			attack_stage = 2
		2:
			# Action ends
			attack_timer.start(attack_decay)
			attack_stage = 3
		3:
			# Decay ends
			attack_stage = 0
