extends Area2D

var tilemap

var tile_size

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


func destroy_block():
	break_wait_timer.start()
	tilemap.set_cell(1, tilemap.local_to_map(position))
	block_break_particle.emitting = true
	get_tree().current_scene.systems.screen_shake.screen_shake(10, 15, 5)
	await break_wait_timer.timeout
	for neighbor in neighbors:
		if neighbor != null:
			neighbor.destroy_block()
	queue_free()
