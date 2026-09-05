extends Node2D

@onready var loot_drop_timer: Timer = $LootDropTimer

const DROP_ANGLE_MIN : float = deg_to_rad(-60)
const DROP_ANGLE_MAX : float = deg_to_rad(-120)
const DROP_SPEED_MIN : float = 160
const DROP_SPEED_MAX : float = 180


func drop(loot : Array[Loot], drop_all_loot_at_once : bool):
	# Handle loot drops
	
	# prep drop array
	var drops : Array[PackedScene]
	for item in loot:
		var amount = max(0, randi_range(item.amount_min, item.amount_max))
		for i in range(amount):
			drops.append(item.item)
	
	# drop all items in array
	for i in drops:
		var collectible = i.instantiate()
		collectible.global_position = global_position
		collectible.spawn_angle = randf_range(DROP_ANGLE_MIN, DROP_ANGLE_MAX)
		collectible.spawn_speed = randf_range(DROP_SPEED_MIN, DROP_SPEED_MAX)
		collectible.is_static = false
		get_tree().current_scene.current_room.loot.add_child(collectible)
		
		loot_drop_timer.start()
		if !drop_all_loot_at_once:
			await loot_drop_timer.timeout
	
	queue_free()
