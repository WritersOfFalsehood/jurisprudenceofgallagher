@icon("res://icons/2d/diamond-yellow.svg")
extends RigidBody2D
class_name Collectible

@onready var timer: Timer = $Timer
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@export var follow_range : float
@export var is_static : bool

signal spawned
signal collected

var is_collectable : bool

var spawn_speed : float
var spawn_angle : float

var is_following : bool

var follow_speed : float
const FOLLOW_MAX_SPEED : float = 500
const FOLLOW_ACCELERATION : float = 400


func _ready() -> void:
	if !is_static:
		on_spawn()
	else:
		freeze = true
		is_collectable = true


func _physics_process(delta: float) -> void:
	hitbox_shape.disabled = !is_collectable
	
	if abs((PlayerProperties.player_object.global_position - global_position).length()) <= follow_range and is_collectable:
		is_following = true
	
	if is_following:
		freeze = true
		follow_speed = min(FOLLOW_MAX_SPEED, follow_speed + FOLLOW_ACCELERATION * delta)
		global_position = global_position.move_toward(PlayerProperties.player_object.global_position, follow_speed * delta)


func on_spawn():
	freeze = false
	apply_impulse(Vector2.from_angle(spawn_angle) * spawn_speed)
	timer.start()


func on_collect(area : Area2D):
	collected.emit()
	queue_free()


func _on_hitbox_area_entered(area: Area2D) -> void:
	on_collect(area)


func _on_timer_timeout() -> void:
	is_collectable = true
