@icon("res://icons/objects/helmet-red.svg")
class_name Enemy
extends CharacterBody2D

@export_group("Drops")
@export var loot : Array[Loot]
@export var drop_all_loot_at_once : bool = true

@export_group("Stats")
@export var max_hp : float
@onready var hp = max_hp
@export var knockback_resistance : float
@export var on_air_knockback_deceleration : float
@export var on_ground_knockback_deceleration : float

@export_group("Flags")
@export var can_move : bool
@export var can_get_hit : bool
@export var can_get_knockbacked : bool
@export var can_hurt : bool
@export var can_take_damage : bool
@export var can_die : bool
@export var can_get_stunned : bool
@export var always_activated : bool

@export_group("Movement")
@export_enum("Left", "Right", "Random") var starting_direction : int = 2
@export var gravity : float
@export var terminal_velocity : float
@export var can_fall : bool
@export var turn_on_edge : bool
@export var follow_beyond_edge : bool
@export var no_clip : bool

@onready var hurtbox = $Hurtbox
@onready var hitbox = $Hitbox
@onready var stun_timer = $StunTimer
@onready var edge_detector_left = $EdgeDetectorLeft
@onready var edge_detector_right = $EdgeDetectorRight
@onready var sprite = $AnimatedSprite2D
@onready var flash_effect_timer = $FlashEffectTimer
@onready var hit_effect: GPUParticles2D = $HitEffect
@onready var hit_particle: GPUParticles2D = $HitParticle
@onready var die_effect: GPUParticles2D = $DieEffect
@onready var die_particle: GPUParticles2D = $DieParticle

const ACTIVATION_RANGE : float = 400
const KNOCKBACK_UP_SPEED : float = 170

signal spawn
signal activated
signal take_damage
signal died

var is_activated : bool

var move_velocity : Vector2
var horizontal_velocity : Vector2
var vertical_velocity : Vector2
var direction : int = 1

var hurt_data : Node2D

var knockback_velocity : Vector2
var is_getting_knockbacked : bool
var knockback_dir : Vector2

var is_stunned : bool

var sprite_modulate_default : Color
var collision_mask_default : int

var loot_dropper_scene : PackedScene = preload("res://objects/loot_dropper.tscn")

func _ready():
	sprite_modulate_default = sprite.modulate
	collision_mask_default= collision_mask
	
	match starting_direction:
		0:
			direction = -1
		1:
			direction = 1
		2:
			direction = randi_range(0, 1) * 2 - 1


func die():
	died.emit()
	# Handle Drop
	var loot_dropper = loot_dropper_scene.instantiate()
	loot_dropper.global_position = global_position
	get_tree().current_scene.current_room.loot.add_child(loot_dropper)
	loot_dropper.drop(loot, drop_all_loot_at_once)
	
	# Despawn enemy
	queue_free()
	
	# death particle effect
	var die_effect_node = die_effect.duplicate()
	var die_particle_node = die_particle.duplicate()
	
	var particles_node = get_tree().current_scene.current_room.particles
	
	particles_node.add_child(die_effect_node)
	particles_node.add_child(die_particle_node)
	
	die_effect_node.global_position = global_position
	die_particle_node.global_position = global_position
	
	die_effect_node.emitting = true
	die_particle_node.emitting = true


func _process(delta):
	if hp <= 0:
		if can_die:
			die()



func _physics_process(delta):
	# enemies only activate after at least 400 blocks from player
	if !is_activated:
		if abs((global_position - get_tree().current_scene.player.global_position).length()) <= ACTIVATION_RANGE or always_activated:
			is_activated = true
			activated.emit()
		else:
			return
	
	
	collision_mask = 0 if no_clip else collision_mask_default
	
	hurtbox.monitorable = can_hurt
	hitbox.monitoring = can_get_hit
	
	if is_getting_knockbacked:
		var knockback_deceleration : float
		if is_on_floor() or !can_fall:
			knockback_deceleration = on_ground_knockback_deceleration
		else:
			knockback_deceleration = on_air_knockback_deceleration
		
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_deceleration * delta)
		if knockback_velocity.length() == 0:
			is_getting_knockbacked = false
	
	if !can_move:
		move_velocity = Vector2.ZERO
		
	velocity = (Vector2.DOWN * velocity.y * int(can_fall)) + move_velocity + knockback_velocity
	if can_fall:
		velocity.y = min(velocity.y + gravity * delta, terminal_velocity)
		
	move_and_slide()


func _on_hitbox_area_entered(area):
	# Get hit by player hurtbox
	await get_tree().physics_frame			# wait to ensure parrying works correctly
	await get_tree().physics_frame			# two frames just work better than one idk
	if area.get_collision_layer_value(5):
		if can_get_hit and can_take_damage:
			if area is Hurtbox:
				if !area.is_parried:
					get_hit(area)


func get_hit(area):
	take_damage.emit()
	area.hit.emit()
	
	Global.hitstop(0.08)
	
	hp -= area.damage
	
	var knockback_direction : int
	var attack_angle : float		# angle of the vector pointing FROM attack source
	
	match area.knockback_direction:
		0:
			knockback_direction = sign(global_position.x - area.global_position.x)
			if knockback_direction == 0:
				knockback_direction = 1
		1:
			knockback_direction = -1
		2:
			knockback_direction = 1
	
	attack_angle = (area.direction * 90) % 360
	
	apply_knockback(knockback_direction, area.knockback_power)
	#recoil effect at the player if the enemy cant get knocked back
	if !can_get_knockbacked and hp > 0:
		area.recoil.emit()
	
	if can_get_stunned:
		stun_timer.start(area.stun_time)
		if area.stun_time:
			is_stunned = true
	
	# Flash effect
	sprite.modulate = Color(100, 100, 100)
	flash_effect_timer.start()
	
	# Hit effect
	var mat = hit_effect.process_material
	mat.angle_min = attack_angle
	mat.angle_max = attack_angle
	hit_effect.emitting = true
	
	hit_particle.rotation_degrees = -attack_angle
	hit_particle.restart()


func apply_knockback(knockback_direction : int, knockback_speed : float):
	if can_get_knockbacked:
		is_getting_knockbacked = true
	
		knockback_dir = Vector2(knockback_direction, 0).normalized()
		knockback_velocity = knockback_dir * knockback_speed / knockback_resistance
		
		# if enemy is flying, the upward motion becomes part of the knockback. if not, it adds a jump aside from the knockback
		if can_fall:
			velocity.y = -KNOCKBACK_UP_SPEED * sign(knockback_speed)
		else:
			knockback_velocity.y = -KNOCKBACK_UP_SPEED * knockback_speed / knockback_resistance / 1000		# shit gets wild if i dont divide like this
	




func _on_flash_effect_timer_timeout():
	sprite.modulate = sprite_modulate_default
