extends AnimatedSprite2D

@onready var player = get_parent()

@onready var dash_particle_pool: ParticlePool = $"../DashParticlePool"
@onready var land_particle_pool: ParticlePool = $"../LandParticlePool"
@onready var land_small_particle_pool: ParticlePool = $"../LandSmallParticlePool"
@onready var slide_particle_pool: ParticlePool = $"../SlideParticlePool"

var physics_frames_passed : int


var animation_index = "idle"
var finalized_animation_index = "idle":
	set(value):
		if finalized_animation_index == value:
			return
		finalized_animation_index = value
		play(finalized_animation_index)


func _ready():
	play(finalized_animation_index)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	flip_h = player.direction_x == -1
	
	if animation_index == "climb":
		flip_h = false
	
	speed_scale = 1
	
	if player.attack_stage == 0:
		if !player.is_on_floor():
			if player.velocity.y < 0:
				animation_index = "jump"
			else:
				animation_index = "fall"
		else:
			if abs(player.velocity.x) < player.MIN_SPEED_X:
				animation_index = "idle"
			elif player.is_turning:
				animation_index = "turn"
			else:
				animation_index = "walk"
		
		if !player.dash_timer.is_stopped():
			animation_index = "roll"
		
		if player.is_dash_jumping:
			animation_index = "dash jump"
		
		if !player.ledge_grab_timer.is_stopped():
			animation_index = "ledge grab"
		
		if player.is_climbing:
			animation_index = "climb"
			speed_scale = Input.get_axis("Down", "Up")
		
		if player.is_sitting:
			animation_index = "sit"
		
		if player.is_getting_knockbacked:
			animation_index = "fall"
	
	finalized_animation_index = animation_index
	
	# invicibility frames
	if player.invisibility_frames_timer.is_stopped():
		modulate.v = 1
	else:
		modulate.v = cos(Time.get_ticks_msec() / 40)
	
	# sliding effect
	if player.is_turning and (physics_frames_passed % 3) == 0:
		slide_particle_pool.emit_particle()
	
	physics_frames_passed += 1

func start_attack(animation_type, combo_count):
	frame = 0
	
	match animation_type:
		player.attack_types.SIDE_ATTACK:
			animation_index = "attack" + " " + str(combo_count)
		player.attack_types.UP_ATTACK:
			animation_index = "attack up"
		player.attack_types.DOWN_ATTACK:
			animation_index = "attack down"
	
	if player.is_climbing:
		animation_index = "climb attack"
	
	play(animation_index)


func dash_particle_emit():
	dash_particle_pool.emit_particle(player.direction_x)


func _on_player_land_on_ground(landing_speed : float) -> void:
	if landing_speed > 270:
		land_particle_pool.emit_particle()
	elif landing_speed > 200:
		land_small_particle_pool.emit_particle()
