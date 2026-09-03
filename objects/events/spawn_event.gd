extends Event

@export var object : PackedScene
@export var spawn_position : Vector2

func on_execute():
	var spawned_object = object.instantiate()
	spawned_object.global_position = spawn_position
	add_child(spawned_object)
