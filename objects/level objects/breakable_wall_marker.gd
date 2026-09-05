extends Area2D

var tilemap : TileMapLayer

var tile_size : int

var neighbors : Array

@onready var break_wait_timer = $BreakWaitTimer
@onready var block_break_particle = $BlockBreakParticle


# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = get_parent()
	tile_size = tilemap.tile_set.tile_size.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func add_neighbor(area):
	if !area in neighbors:
		neighbors.append(area)


func _on_area_entered(area):
	if area.get_collision_layer_value(5):
		destroy_block()
		if area is Hurtbox:
			area.hit.emit()


func destroy_block():
	break_wait_timer.start()
	
	#create particle
	var block_break_particle_node : GPUParticles2D = block_break_particle.duplicate()
	var particles_node : Node = get_tree().current_scene.current_room.particles
	
	particles_node.add_child(block_break_particle_node)
	block_break_particle_node.global_position = global_position
	block_break_particle_node.emitting = true
	
	var tilemap_layer_breakable_wall : TileMapLayer = tilemap.get_parent().get_child(tilemap.get_index() + 1)
	tilemap_layer_breakable_wall.set_cell(tilemap.local_to_map(global_position))
	
	get_tree().current_scene.systems.screen_shake.screen_shake(10, 15, 5)
	
	#destroy adjacent blocks
	await break_wait_timer.timeout
	for neighbor in neighbors:
		if neighbor != null:
			neighbor.destroy_block()
	
	queue_free()
