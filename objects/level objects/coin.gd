extends Collectible

@export var value : int


func _ready() -> void:
	super._ready()
	$AnimatedSprite2D.frame = randi_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))


func on_collect(area : Area2D):
	get_tree().current_scene.systems.player_properties.gold += value
	super.on_collect(area)
