extends CanvasLayer


@onready var control = $Control

@onready var hearts = $Control/PanelContainer/MarginContainer/HBoxContainer/Hearts
@onready var gold_counter_text = $Control/PanelContainer/MarginContainer/HBoxContainer/GoldCounter/RichTextLabel

var heart_sprites

var heart_count : float
var gold_count : float

const MAX_HEARTS : int = 10
const HEART_ANIMATION_FRAME_COUNT = 7

const HEART_INCREASE_RATE : float = 60
const GOLD_INCREASE_RATE : float = 120


func _ready() -> void:
	heart_sprites = hearts.get_children()
	
	heart_count = PlayerProperties.hp * HEART_ANIMATION_FRAME_COUNT
	gold_count = PlayerProperties.gold



func _process(delta: float) -> void:
	# only show the unlocked amount of hearts
	var index = 0
	for heart_container in heart_sprites:
		var heart_sprite = heart_container.get_child(0)
		heart_sprite.visible = index < PlayerProperties.max_hp
		index += 1
	
	

func _physics_process(delta: float) -> void:
	if PlayerProperties.hp < floor(heart_count / HEART_ANIMATION_FRAME_COUNT):
		# REPLACE WITH DAMAGE FLASHING CODE
		pass
	
	# heart count gets intantly snapped to hp when hp drops, but gradually builds up when hp increases
	# gold count moves gradually in either direction
	heart_count += HEART_INCREASE_RATE * delta
	heart_count = min(heart_count, PlayerProperties.hp * HEART_ANIMATION_FRAME_COUNT)
	
	var full_heart_count : int = floor(heart_count / HEART_ANIMATION_FRAME_COUNT)
	var remainder_heart_count : int = floor(floori(heart_count) % HEART_ANIMATION_FRAME_COUNT)
	
	# update heart boxes accordingly
	var index = 0
	for heart_container in heart_sprites:
		var heart_sprite = heart_container.get_child(0)
		if index < full_heart_count:
			heart_sprite.frame = HEART_ANIMATION_FRAME_COUNT - 1
		elif index == full_heart_count:
			heart_sprite.frame = remainder_heart_count
		else:
			heart_sprite.frame = 0
		index += 1
	
	# update gold count
	gold_count += min(abs(PlayerProperties.gold - gold_count), GOLD_INCREASE_RATE * delta) * sign(PlayerProperties.gold - gold_count)
	gold_counter_text.text = var_to_str(int(gold_count))
	
