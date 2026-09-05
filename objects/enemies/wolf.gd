extends Enemy

@export var walk_speed : float
@export var run_speed : float
@export var engage_range : float
@export var disengage_range : float
@export var jump_speed : float

@onready var ai_state_timer: Timer = $AIStateTimer
@onready var follow_object = get_tree().current_scene.player

var ai_state : int

@onready var rectangle0 : RectangleShape2D = $Hitbox/CollisionShape2D.shape
@onready var rectangle1 : RectangleShape2D = $Hitbox/CollisionShape2D2.shape

var target_move_velocity : Vector2
const MOVE_LERP : float = 0.05

func _ready():
	super._ready()
	
	$Hitbox/CollisionShape2D2.disabled = true
	$Hurtbox/CollisionShape2D2.disabled = true


func _physics_process(delta: float) -> void:
	if is_getting_knockbacked:
		ai_state_timer.stop()
		move_velocity = Vector2.ZERO
		ai_state = -1
		
		direction = -sign(velocity.x)
		if direction == 0:
			direction = 1
	
	if is_stunned:
		ai_state_timer.stop()
		move_velocity = Vector2.ZERO
		ai_state = -2
	
	match ai_state:
		# getting stunned
		-2:
			if !is_stunned:
				ai_state = 0
		
		# getting knockbacked
		-1:
			sprite.play("knockback")
			if !is_getting_knockbacked:
				ai_state = 0
		
		# sitting
		0:
			sprite.play("sit")
			move_velocity = Vector2.ZERO
			
			if ai_state_timer.is_stopped():
				#time spent walking
				ai_state_timer.start(randf_range(1.5, 2.5))
				direction = randi_range(0, 1) * 2 - 1
				
				#switch to walking
				ai_state = 1
			
			if global_position.distance_to(follow_object.global_position) <= engage_range:
				#switch to running
				ai_state = 2
		
		# walking
		1:
			sprite.play("walk")
			
			if is_on_wall():
				direction *= -1
			
			#dont wander off edges
			if turn_on_edge and is_on_floor():
				if !edge_detector_left.has_overlapping_bodies():
					direction = 1
				if !edge_detector_right.has_overlapping_bodies():
					direction = -1
			
			move_velocity = Vector2.RIGHT * direction * walk_speed
			
			if ai_state_timer.is_stopped():
				#time spent sitting
				ai_state_timer.start(randf_range(0.3, 2))
				
				#switch to sitting
				ai_state = 0
			
			if global_position.distance_to(follow_object.global_position) <= engage_range:
				#switch to running
				ai_state = 2
		
		# running
		2:
			sprite.play("run")
			
			direction = sign(follow_object.global_position.x - global_position.x)
			if direction == 0:
				direction = 1
			
			target_move_velocity = Vector2.RIGHT * direction * run_speed
			move_velocity = move_velocity.lerp(target_move_velocity, MOVE_LERP)
			
			#run over edges while chasing player
			if !follow_beyond_edge and is_on_floor():
				if !edge_detector_left.has_overlapping_bodies() and direction == -1:
					move_velocity = Vector2.ZERO
				if !edge_detector_right.has_overlapping_bodies() and direction == 1:
					move_velocity = Vector2.ZERO
			
			if global_position.distance_to(follow_object.global_position) >= disengage_range:
				#switch to sitting
				ai_state = 0
		
		# jumping
		3:
			if velocity.y < 0:
				sprite.play("jump")
			else:
				sprite.play("fall")
			
			if is_on_floor() and velocity.y >= 0:
				# switch to sitting
				ai_state = 0
	
	match ai_state:
		3:
			$Hitbox/CollisionShape2D.shape = rectangle1
			$Hurtbox/CollisionShape2D.shape = rectangle1
		_:
			$Hitbox/CollisionShape2D.shape = rectangle0
			$Hurtbox/CollisionShape2D.shape = rectangle0
	
	sprite.flip_h = direction != 1
	
	super._physics_process(delta)
