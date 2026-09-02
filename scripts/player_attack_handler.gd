extends Node2D

# ATTACK TIME VALUES

var attack_damage = [15, 15, 20]
var attack_knockback = [50, 50, 60]
var attack_onset = 0.05
var attack_action = 0.07
var attack_decay = 0.2
var attack_combo_before_window = 0.12		#time from beginning of attack to being able to hit combo
var attack_combo_window = 0.16		#time window for bring able to combo


var active_weapon_index : int

@onready var weapons = get_children()

@onready var player = get_parent()

signal hit
signal parried


func _ready():
	for hitbox in weapons:
		hitbox.collision_shape.disabled = true


func _process(delta):
	weapons[0].scale.x = player.direction_x
	weapons[0].direction = 1 - player.direction_x
	
	weapons[active_weapon_index].collision_shape.disabled = player.attack_stage != 2


func on_player_weapon_hit():
	hit.emit()


func on_player_weapon_parry():
	parried.emit()
