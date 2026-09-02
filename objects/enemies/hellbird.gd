extends Enemy


@export var projectile : PackedScene

@export_group("Behaviour")
@export_enum("Wander and Follow", "Continuous Movement") var movement_behaviour : int
@export var wander_speed : float
@export var follow_speed : float
@export var engage_range : float
@export var disengage_range : float
@export var attack_range : float
@export var fireball_speed : float

@export_group("Flapping")
@export var flapping_amplitude : float
@export var flapping_frequency : float

@export_group("Diving")
@export var diving_initial_vertical_speed : float
@export var diving_upward_acceleration : float
@export var diving_horizontal_speed : float

@onready var ai_state_timer = $AIStateTimer
@onready var attack_cooldown_timer = $AttackCooldownTimer

@onready var projectiles_node = get_tree().current_scene.get_node("Projectiles")

@onready var follow_object = PlayerProperties.player_object

const FLY_LERP = 0.1

var ai_state : int

var home_height : float

var target_velocity_x : float

var time_passed : float

var chosen_attack : int			#0 : fireball, 1 : perch



func _ready():
	home_height = global_position.y
	
	super._ready()


func process_flap(delta):
	time_passed += delta
	var angular_velocity = 2 * PI * flapping_frequency
	move_velocity.y = -flapping_amplitude * angular_velocity * sin(angular_velocity * time_passed)


func _physics_process(delta):
	
	if is_getting_knockbacked:
		ai_state_timer.stop()
		ai_state = -1
	
	if is_stunned:
		ai_state_timer.stop()
		ai_state = -2
	
	sprite.play("fly")
	
	match ai_state:
		# getting stunned
		-2:
			move_velocity = Vector2.ZERO
			if !is_stunned:
				ai_state = 0
		
		# getting knockbacked
		-1:
			move_velocity = Vector2.ZERO
			if !is_getting_knockbacked:
				ai_state = 0
		
		# waiting
		0:
			process_flap(delta)
			target_velocity_x = 0
			move_velocity.x = lerp(move_velocity.x, target_velocity_x, FLY_LERP)
			
			#switch to wandering
			if ai_state_timer.is_stopped() or movement_behaviour == 1:
				if movement_behaviour == 0:
					#time spent wandering
					ai_state_timer.start(randf_range(1.5, 2.5))
					direction = randi_range(0, 1) * 2 - 1
				
				ai_state = 1
			
			if global_position.distance_to(follow_object.global_position) <= engage_range and global_position.y < follow_object.global_position.y and movement_behaviour == 0:
				#switch to following
				ai_state = 2
		
		# wandering
		1:
			process_flap(delta)
			if is_on_wall():
				direction *= -1
				move_velocity.x *= -1
			
			target_velocity_x = direction * wander_speed
			move_velocity.x = lerp(move_velocity.x, target_velocity_x, FLY_LERP)
			
			#switch to waiting
			if ai_state_timer.is_stopped():
				#time spent waiting
				ai_state_timer.start(randf_range(0.3, 2))
				
				ai_state = 0
			
			if global_position.distance_to(follow_object.global_position) <= engage_range and global_position.y < follow_object.global_position.y and movement_behaviour == 0:
				#switch to following
				ai_state = 2
			
			if global_position.distance_to(follow_object.global_position) <= attack_range and global_position.y < follow_object.global_position.y and movement_behaviour == 1:
				if attack_cooldown_timer.is_stopped():
					# time initiating_attack
					ai_state_timer.start(0.7)
					
					direction = sign(follow_object.global_position.x - global_position.x)
					chosen_attack = randi_range(0, 1)
					
					if chosen_attack == 0:
						ai_state = 3
					else:
						ai_state = 4
					
					attack_cooldown_timer.start()
		
		# following
		2:
			process_flap(delta)
			
			direction = sign(follow_object.global_position.x - global_position.x)
			
			target_velocity_x = direction * follow_speed
			move_velocity.x = lerp(move_velocity.x, target_velocity_x, FLY_LERP)
			
			# switch to waiting
			if global_position.distance_to(follow_object.global_position) >= disengage_range or global_position.y > follow_object.global_position.y:
				ai_state = 0
			
			# initiate attack
			if global_position.distance_to(follow_object.global_position) <= attack_range and global_position.y < follow_object.global_position.y:
				if attack_cooldown_timer.is_stopped():
					# time initiating_attack
					ai_state_timer.start(0.7)
					
					chosen_attack = randi_range(0, 1)
					
					if chosen_attack == 0:
						ai_state = 3
					else:
						ai_state = 4
					
					attack_cooldown_timer.start()
		
		# initiate fireball
		3:
			move_velocity = Vector2.ZERO
			
			# do fireball
			if ai_state_timer.is_stopped():
				# time pausing after shooting fireballs
				ai_state_timer.start(0.7)
				
				# shoot fireballs
				var shooting_angle = PI / 16
				
				for i in range(3):
					var shot_projectile = projectile.instantiate()
					
					shot_projectile.global_position = global_position
					shot_projectile.move_velocity = Vector2.from_angle(shooting_angle) * fireball_speed
					shot_projectile.move_velocity.x *= direction
					projectiles_node.add_child(shot_projectile)
					
					shooting_angle += PI * 1 / 8
				
				ai_state = 5
			
			sprite.play("fireball ready")
		
		# initiate dive
		4:
			move_velocity = Vector2.ZERO
			
			# start dive
			if ai_state_timer.is_stopped():
				# max diving time
				ai_state_timer.start(4)
				
				home_height = global_position.y
				
				move_velocity.y = diving_initial_vertical_speed
				
				ai_state = 6
		
		# shooting
		5:
			move_velocity = Vector2.ZERO
			
			if ai_state_timer.is_stopped():
				ai_state = 0
				
				attack_cooldown_timer.start()
			
			sprite.play("fireball shoot")
		
		# diving
		6:
			move_velocity.x = diving_horizontal_speed * direction
			
			move_velocity.y -= diving_upward_acceleration * delta
			
			if ai_state_timer.is_stopped():
				ai_state = 0
				
				attack_cooldown_timer.start()
			
			if global_position.y < home_height:
				global_position.y = home_height
				ai_state = 0
				
				attack_cooldown_timer.start()
			
			sprite.play("dive")
	
	
	
	sprite.flip_h = direction == -1
	
	super._physics_process(delta)
