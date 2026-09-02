extends Node2D

@onready var upper_raycast = $UpperRaycast
@onready var middle_raycast = $MiddleRaycast
@onready var lower_raycast = $LowerRaycast
@onready var gap_checker_raycast = $GapCheckerRaycast

var is_on_ledge : bool
var enabled : bool = true


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	upper_raycast.enabled = enabled
	middle_raycast.enabled = enabled
	lower_raycast.enabled = enabled
	gap_checker_raycast.enabled = enabled
	
	is_on_ledge = !upper_raycast.is_colliding() and !gap_checker_raycast.is_colliding() and middle_raycast.is_colliding() and lower_raycast.is_colliding()
