@icon("res://icons/2d/dotspark-blue.svg")
extends Node2D
class_name ParticlePool

@export_range(1, 32) var pool_size : int

@onready var particle_node = get_child(0)

var image_flip_map : Array[bool]


func _ready() -> void:
	image_flip_map.resize(pool_size)
	
	for i in range(pool_size - 1):
		var new_particle_node = particle_node.duplicate()
		add_child(new_particle_node)


func emit_particle(direction : int = 1):
	var index : int = 0
	for particle in get_children():
		if !particle.emitting:
			if image_flip_map[index] != (direction == -1):
				# flip image
				var image = particle.texture.get_image()
				image.flip_x()
				particle.texture = ImageTexture.create_from_image(image)
				image_flip_map[index] = !image_flip_map[index]
			
			particle.scale.x = direction
			particle.restart()
			return
		index += 1
	get_child(0).restart()
