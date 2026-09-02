@icon("res://icons/objects/arrow-red.svg")
extends Enemy
class_name Projectile


@export_enum("Nothing", "Destroy", "Bounce") var on_wall_hit : int
@export_enum("Nothing", "Destroy", "Bounce") var on_floor_hit : int
@export_enum("Nothing", "Destroy", "Bounce") var on_ceiling_hit : int
@export var can_pierce : bool
@export var can_rotate : bool


func _ready():
	
	super._ready()


func _physics_process(delta):
	if is_on_wall():
		match on_wall_hit:
			1:
				die()
			2:
				move_velocity.x *= -1
	if is_on_floor():
		match on_floor_hit:
			1:
				die()
			2:
				move_velocity.y *= -1
	if is_on_ceiling():
		match on_ceiling_hit:
			1:
				die()
			2:
				move_velocity.y *= -1
	
	if can_rotate:
		rotation = move_velocity.angle()
	
	super._physics_process(delta)


func get_hit(area):
	take_damage.emit()
	area.hit.emit()
	
	if can_die:
		die()


func _on_hurtbox_hit():
	if !can_pierce:
		die()
