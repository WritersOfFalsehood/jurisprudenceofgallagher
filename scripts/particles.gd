extends Node2D


func _process(delta: float) -> void:
	var particle_array : Array[Node] = get_children()
	
	for particle_node in particle_array:
		if particle_node is GPUParticles2D:
			if particle_node.one_shot and !particle_node.emitting:
				particle_node.queue_free()
