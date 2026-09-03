extends CharacterBody2D


@onready var player_sprite = $PlayerSprite
@onready var collision_shape = $CollisionShape2D
@onready var hitbox = $Hitbox
@onready var player_attack_handler = $PlayerAttackHandler

@onready var attack_timer = $AttackTimer
@onready var attack_combo_timer = $AttackComboTimer

@onready var invisibility_frames_timer = $InvisibilityFramesTimer

@onready var dash_timer = $DashTimer
@onready var dash_jump_timer = $DashJumpTimer

@onready var ledge_detector = $LedgeDetector
@onready var ledge_grab_timer = $LedgeGrabTimer

const MAX_SPEED_X = 90
const MIN_SPEED_X = 5
const MIN_KNOCKBACK_SPEED = 15
const RECOIL_SPEED = 150

const JUMP_SPEED = 225
const POGO_SPEED = 220
const GRAV_NORMAL = 975
const GRAV_HOLDING_JUMP = 512
const TERMINAL_VELOCITY = 275

const KNOCKBACK_UP_SPEED = 200
const ON_GROUND_KNOCKBACK_DECELERATION = 400
const ON_AIR_KNOCKBACK_DECELERATION = 75

const DASH_SPEED = 220
const ON_GROUND_DASH_DECELERATION = 250
const ON_AIR_DASH_DECELERATION = 75
const DASH_JUMP_SPEED_X = 240
const DASH_JUMP_SPEED_Y = 160

const ON_GROUND_WALK_ACCELERATION = 2000
const HOLD_BUTTON_COUNTER_ACCELERATION = 450
const ON_GROUND_DECELERATION = 750.0

const SLASH_SPEED = 275
const SLASH_RANGE = 60
const SLASH_MIN_ANGLE = deg_to_rad(30)
const SLASH_MAX_ANGLE = deg_to_rad(60)

const LEDGE_GRAB_MIN_Y_SPEED = -150

const CLIMB_SPEED = 80

signal take_damage
signal jump
signal dash
signal dash_jump
signal attack
signal start_climbing
signal stop_climbing
signal ledge_grab
signal land_on_ground(landing_speed : float)

var last_collision : KinematicCollision2D
var previous_frame_is_grounded : bool = true

var acceleration_x : float
var acceleration_y : float

var direction_x = 1
var is_turning : bool
var is_ducking : bool
var is_jumping : bool
var is_dash_jumping : bool
var is_getting_knockbacked : bool
var is_climbing : bool
var is_sitting : bool

var current_acceleration : float
var current_deceleration : float

var knockback_direction : int
var knockback_velocity : Vector2

var can_attack = true
var can_move = true
var can_slash : bool

var slashable_object : Node
var slash_angle : float

var default_dash_time : float			# need this cuz i have to set dash time to different values in some situations

var current_ladder : Area2D
var is_touching_ladder : bool
var ladder_upper_bound : float
var ladder_lower_bound : float

var ignore_player_input : bool
var simulated_inputs := {}

var current_transition_direction : Vector2		# used to move player into screen transitions

enum attack_types {
	SIDE_ATTACK,
	UP_ATTACK,
	DOWN_ATTACK
}

var attack_type : int

var attack_stage : int
# 0 = not attacking, 1 = onset, 2 = action, 3 = decay

var combo_stage : int
# 0 = not attacking, 1 = before combo window, 2 = at combo window

var combo_count : int


func _ready():
	PlayerProperties.player_object = self
	
	default_dash_time = dash_timer.wait_time
	
	#inherit direction from player properties in case of screen transitioning
	if PlayerProperties.player_direction_in_next_scene != 0:
		direction_x = PlayerProperties.player_direction_in_next_scene
		PlayerProperties.player_direction_in_next_scene = 0
	
	#prepare simulated input dictionary
	for action in InputMap.get_actions():
		simulated_inputs[action] = false


func _process(delta):
	pass


func is_input_action_active(action : StringName):
	if simulated_inputs.get(action, false):
		return true
	
	if ignore_player_input:
		return false
	
	return Input.is_action_pressed(action)


func get_axis(neg_action : StringName, pos_action : StringName):
	if simulated_inputs.get(neg_action) or simulated_inputs.get(pos_action):
		var neg = 1.0 if simulated_inputs.get(neg_action) else 0.0
		var pos = 1.0 if simulated_inputs.get(pos_action) else 0.0
		return pos - neg
	
	if ignore_player_input:
		return 0.0
	
	return Input.get_axis(neg_action, pos_action)


func on_jump_input():
	if can_move:
		velocity.y = -JUMP_SPEED
		is_jumping = true
		is_climbing = false
		
		jump.emit()
		stop_climbing.emit()
	elif !dash_timer.is_stopped() and dash_jump_timer.is_stopped():
		# dash jumping
		dash_timer.start(0.35)			# to keep dash deceleration longer
		velocity.y = -DASH_JUMP_SPEED_Y
		velocity.x = DASH_JUMP_SPEED_X * direction_x
		is_jumping = true
		is_dash_jumping = true
		
		dash_jump.emit()


func on_attack_input():
		
		# Verify Direction
		if sign(get_axis("Left", "Right")) != 0:
			direction_x = sign(get_axis("Left", "Right"))
		
		var is_attacking_up = is_input_action_active("Up")
		var is_attacking_down = is_input_action_active("Down") and !is_on_floor()
		
		var can_combo = combo_stage == 2 and combo_count <= 2 and !is_attacking_up and !is_attacking_down and !is_climbing
		
		if can_attack and (attack_stage == 0 or can_combo):
			if can_move or can_combo or !dash_timer.is_stopped():	# Have to do this exclusion so that dash cencelling works correctly
				# Dash Cancel
				dash_timer.stop()
				var input_x_axis = sign(get_axis("Left", "Right"))
				if input_x_axis != 0:
					direction_x = input_x_axis
				
				# Attack
				attack.emit()
				
				attack_timer.stop()
				attack_combo_timer.stop()
				
				attack_timer.start(player_attack_handler.attack_onset)
				attack_stage = 1
				
				if !is_attacking_up and !is_attacking_down:
					attack_combo_timer.start(player_attack_handler.attack_combo_before_window)
					combo_stage = 1
					combo_count += 1
				
				if is_attacking_up:
					attack_type = attack_types.UP_ATTACK
				elif is_attacking_down:
					attack_type = attack_types.DOWN_ATTACK
				else:
					attack_type = attack_types.SIDE_ATTACK
				
				# climb attacks default to side
				if is_climbing:
					attack_type = attack_types.SIDE_ATTACK
				
				player_attack_handler.active_weapon_index = attack_type
				
				# Start attack anim
				player_sprite.start_attack(player_attack_handler.active_weapon_index, combo_count)


func on_dash_input():
	dash.emit()
	
	# Verify Direction
	if sign(get_axis("Left", "Right")) != 0:
		direction_x = sign(get_axis("Left", "Right"))
	
	dash_timer.start(default_dash_time)
	dash_jump_timer.start()				#timeframe before you can jump out of a dash
	velocity = Vector2.RIGHT * direction_x * DASH_SPEED
	
	is_dash_jumping = false


func on_climb_input():
	is_climbing = true
	
	# do a premature check to prevent snapping
	if is_on_floor() and !is_input_action_active("Up") and abs(position.y - ladder_lower_bound) < 1:
		is_climbing = false
	
	if is_climbing:
		start_climbing.emit()




func _input(event):
	if !ignore_player_input:
		# Attacking
		if event.is_action_pressed("Attack"):
			on_attack_input()
		
		if can_move:
			# Dashing
			if event.is_action_pressed("Dash") and !is_climbing:
				on_dash_input()
			
			# Climbing
			if (event.is_action_pressed("Up") or event.is_action_pressed("Down")) and is_touching_ladder:
				on_climb_input()
		
		# Get up from sitting
		if event.is_action_pressed("Left") or event.is_action_pressed("Right") or event.is_action_pressed("Jump") or event.is_action_pressed("Up"):
			is_sitting = false



func _physics_process(delta):
	# INPUT
	if simulated_inputs["Jump"]:
		on_jump_input()
		simulated_inputs["Jump"] = false
	if simulated_inputs["Attack"]:
		on_attack_input()
		simulated_inputs["Attack"] = false
	if simulated_inputs["Dash"]:
		on_dash_input()
		simulated_inputs["Dash"] = false
	if simulated_inputs["Up"] or simulated_inputs["Down"]:
		on_climb_input()
	
	if RoomTransitioner.is_transitioning:
		can_move = false
	
	var input_x_axis = sign(get_axis("Left", "Right"))
	var input_y_axis = sign(get_axis("Up", "Down"))
	var is_pressing_down = is_input_action_active("Down")
	var is_pressing_up = is_input_action_active("Up")
	var is_pressing_jump = is_input_action_active("Jump")
	
	# MOVEMENT
	
	if !can_move:
		input_x_axis = 0
		input_y_axis = 0
	
	# Add the gravity and terminal velocity
	acceleration_y = GRAV_HOLDING_JUMP if is_pressing_jump else GRAV_NORMAL
	velocity.y += acceleration_y * delta
	velocity.y = min(velocity.y, TERMINAL_VELOCITY)
	
	# Jumping
	if is_on_floor():
		is_jumping = false
		is_dash_jumping = false
		
	# Jumping
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or is_climbing) and !ignore_player_input:
		on_jump_input()
	
	# Horizontal direction and movement
	is_turning = false
	
	if can_move:
		if input_x_axis != 0:
			#if attacking on air direction dosnt change
			if attack_stage == 0 or attack_type != attack_types.SIDE_ATTACK:
				direction_x = input_x_axis
			is_turning = sign(velocity.x) == direction_x * -1
			
			if is_turning and is_on_floor():
				current_acceleration = HOLD_BUTTON_COUNTER_ACCELERATION
			else:
				current_acceleration = ON_GROUND_WALK_ACCELERATION
			
			acceleration_x = current_acceleration * input_x_axis
			
			if not abs(velocity.x) > MAX_SPEED_X:
				velocity.x += acceleration_x * delta
	
	
	# Deceleration
	if !dash_timer.is_stopped():
		if is_on_floor():
			acceleration_x = ON_GROUND_DASH_DECELERATION * -sign(velocity.x)
		else:
			acceleration_x = ON_AIR_DASH_DECELERATION * -sign(velocity.x)
		velocity.x = move_toward(velocity.x, 0, abs(acceleration_x * delta))
	elif !is_getting_knockbacked and input_x_axis == 0:
		acceleration_x = ON_GROUND_DECELERATION * -sign(velocity.x)
		velocity.x = move_toward(velocity.x, 0, abs(acceleration_x * delta))
	
	
	#Apply max speed
	if can_move:
		if abs(velocity.x) > MAX_SPEED_X:
			var speed_difference = abs(velocity.x) - MAX_SPEED_X
			var acceleration_multiplier = 0.8 * exp(-(speed_difference / 90) ** 8) + 0.2
			# Gaussian function so that higher speeds get decelerated less and lower speeds work close to normal
			velocity.x -= min(speed_difference, current_acceleration * acceleration_multiplier * delta) * sign(velocity.x)
			#Remove an extra bit of speed to slow down more
			velocity.x -= delta * sign(velocity.x)
	
	#If speed falls below min speed set it to 0
	if abs(velocity.x) < MIN_SPEED_X:
		velocity.x = 0
	
	#Keep within level borders
	if get_tree().current_scene is Room and !RoomTransitioner.is_transitioning:
		position.x = clampf(position.x, -1, get_tree().current_scene.room_size.x + 1)
	
	# Apply knockback
	if is_getting_knockbacked:
		attack_stage = 0
		direction_x = knockback_direction * -1
		
		var current_knockback_deceleration
		if is_on_floor():
			current_knockback_deceleration = ON_GROUND_KNOCKBACK_DECELERATION
		else:
			current_knockback_deceleration = ON_AIR_KNOCKBACK_DECELERATION
		
		knockback_velocity.x = move_toward(knockback_velocity.x, 0, current_knockback_deceleration * delta)
		
		if abs(knockback_velocity.x) < MIN_KNOCKBACK_SPEED:
			is_getting_knockbacked = false
		
		velocity = knockback_velocity + Vector2.DOWN * velocity.y
	
	
	# Finalize and apply movement
	can_move = !is_getting_knockbacked and dash_timer.is_stopped() and ledge_grab_timer.is_stopped() and !is_sitting
	
	# cant move if attacking on ground or ladder
	if attack_stage != 0 and attack_type == attack_types.SIDE_ATTACK and (is_on_floor() or is_climbing):
		can_move = false
	
	# Cant move in dialogue
	if PlayerProperties.is_talking:
		can_move = false
		can_attack = false
	else:
		can_attack = true
	
	# LEDGE GRABBING
	ledge_detector.scale.x = direction_x
	
	# initiate ledge grab if on a ledge, on the wall and inputing movement towards ledge
	if ledge_detector.is_on_ledge and is_on_wall_only() and input_x_axis == direction_x and velocity.y >= LEDGE_GRAB_MIN_Y_SPEED and ledge_grab_timer.is_stopped():
		ledge_grab_timer.start()
		ledge_grab.emit()
		# round y position to work with it on a grid
		position.y = floor(position.y)
	
	# ledge grab process
	if !ledge_grab_timer.is_stopped():
		velocity = Vector2.ZERO
		# snap y position to ledge
		while ledge_detector.middle_raycast.is_colliding():
			position.y -= 1
			ledge_detector.middle_raycast.force_raycast_update()
		
	# LADDER CLIMBING
	set_collision_mask_value(11, !is_climbing)
	if is_climbing:
		position.x = current_ladder.position.x
		velocity = Vector2.DOWN * input_y_axis * CLIMB_SPEED
		
		if position.y < ladder_upper_bound - 1 or position.y > ladder_lower_bound + 1:
			is_climbing = false
		
		if is_on_floor() and !Input.is_action_pressed("Up") and abs(position.y - ladder_lower_bound) < 1:
			is_climbing = false
	
	if RoomTransitioner.is_transitioning:
		velocity = current_transition_direction * 50
	
	var landing_speed = velocity.y
	
	move_and_slide()
	
	# check if just landed
	if !previous_frame_is_grounded and is_on_floor():
		land_on_ground.emit(landing_speed)
	previous_frame_is_grounded = is_on_floor()




func _on_attack_timer_timeout():
	match attack_stage:
		1:
			# Onset ends
			attack_timer.start(player_attack_handler.attack_action)
			attack_stage = 2
		2:
			# Action ends
			attack_timer.start(player_attack_handler.attack_decay)
			attack_stage = 3
		3:
			# Decay ends
			attack_stage = 0
			combo_count = 0

func _on_attack_combo_timer_timeout():
	match combo_stage:
		1:
			# Combo window starts
			attack_combo_timer.start(player_attack_handler.attack_combo_window)
			combo_stage = 2
		2:
			# Combo window ends
			combo_stage = 0
			combo_count = 0


func _on_hitbox_area_entered(area):
	# Collide with ladder
	if area.get_collision_layer_value(10):
		current_ladder = area
		is_touching_ladder = true
		
		var ladder_size : Vector2 = Vector2(area.get_child(0).shape.size.x * area.scale.x, area.get_child(0).shape.size.y * area.scale.y)
		
		ladder_upper_bound = area.position.y - ladder_size.y / 2
		ladder_lower_bound = area.position.y + ladder_size.y / 2
	
	
	# Get hit by enemy hurtbox
	await get_tree().physics_frame			# wait to ensure parrying works correctly
	if area.get_collision_layer_value(6):
		if area is Hurtbox:
			if !area.is_parried:
				if invisibility_frames_timer.is_stopped():
					# Getting hit
					take_damage.emit()
					area.hit.emit()
					
					PlayerProperties.hp -= 1
					
					invisibility_frames_timer.start()
					
					# Stop other states
					dash_timer.stop()
					ledge_grab_timer.stop()
					is_climbing = false
					is_sitting = false
					
					# Apply knockback
					is_getting_knockbacked = true
					
					match area.knockback_direction:
						0:
							knockback_direction = sign(global_position.x - area.global_position.x)
						1:
							knockback_direction = -1
						2:
							knockback_direction = 1
					
					if knockback_direction == 0:
						knockback_direction = 1
					
					knockback_velocity = Vector2.RIGHT * knockback_direction * area.knockback_power
					velocity.y = -KNOCKBACK_UP_SPEED
					
					HitstopManager.hitstop(0.12)
					ScreenShake.screen_shake(15, 25, 5)


func _on_hitbox_area_exited(area: Area2D) -> void:
	# Collide with ladder
	if area.get_collision_layer_value(10):
		is_touching_ladder = false


func _on_down_attack_hit():
	velocity.y = -POGO_SPEED


func _on_down_attack_parried():
	velocity.y = -POGO_SPEED


func _on_up_attack_hit():
	velocity.y = 0


func _on_up_attack_parried():
	velocity.y = 0


func _on_side_attack_recoil():
	velocity.x = RECOIL_SPEED * -direction_x


func _on_ledge_grab_timer_timeout() -> void:
	# move player to top of ledge once ledge grabbing finishes
	# move up the distance between middle raycast and player's feet
	# move forward one player width plus two pixels cuz of the animation
	# await one frame to let the animation update correctly
	await get_tree().physics_frame
	position.y += ledge_detector.middle_raycast.position.y
	position.x += (collision_shape.shape.size.x + 2) * direction_x
