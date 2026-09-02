extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_point: Node2D = $SpawnPoint
@onready var follow_object = PlayerProperties.player_object
@onready var enemies_node = get_tree().current_scene.get_node("Enemies")

@export var hiding_object : PackedScene
@export var look_range : float
@export var jump_range : float
@export var jump_speed : float

var has_jumped : bool

var state : int


func _process(delta: float) -> void:
	match state:
		0:
			sprite.play("default")
			if global_position.distance_to(follow_object.global_position) < look_range:
				state = 1
		1:
			sprite.play("look")
			if global_position.distance_to(follow_object.global_position) >= look_range:
				state = 0
			
			if global_position.distance_to(follow_object.global_position) < jump_range and !has_jumped:
				sprite.play("rustle")
				state = 2
	


func jump():
	has_jumped = true
	var spawned_object = hiding_object.instantiate()
	spawned_object.global_position = spawn_point.global_position
	spawned_object.ai_state = 3
	spawned_object.velocity.y = -jump_speed
	enemies_node.add_child(spawned_object)
	sprite.play("jump")


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "rustle":
		if !has_jumped:
			jump()
	elif sprite.animation == "jump":
		queue_free()
