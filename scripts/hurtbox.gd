@icon("res://icons/objects/sword-red.svg")
class_name Hurtbox


extends Area2D

signal hit
signal parried
signal recoil		#for when the player hits an enemy and it gives the player a knockback

@export var damage : float
@export var knockback_power : float
@export_enum("Right", "Up", "Left", "Down", "Zero") var direction : int
@export_enum("Position", "Left", "Right") var knockback_direction : int
@export var stun_time : float
@export var parryable : bool
@export var can_hit_through_parry : bool
@export var collision_shape : CollisionShape2D
@export var always_enabled : bool

var origin_pos : Vector2
var is_parried : bool				#whether last attack was parried



func _physics_process(delta):
	#make sure that the hurtboxes properly reset their parried status
	if collision_shape.disabled:
		is_parried = false


func _on_area_entered(area):
	if parryable:
		if area.get_collision_layer_value(5):
			if area is Hurtbox:
				if area.parryable:
					is_parried = true
					area.is_parried = true
					parried.emit()
					area.parried.emit()
