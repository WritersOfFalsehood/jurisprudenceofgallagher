@icon("res://icons/2d/double-chevron-up-white.svg")
extends Resource
class_name ForcedPlayerMovement

## Input action to execute
## 'Move to Point' makes the player go to that point until it reaches that x coordinate relative to the event object
@export_enum("Left", "Right", "Up", "Down", "Jump", "Attack", "Dash", "Interact", "Move to Point") var input_action : String
## How much the input gets pressed for in seconds
## If 'Move to Point' is selected, then instead this denotes the x coordinate of the finishing point related to the event object
@export var duration : float
## Time waited until the next input gets pressed in seconds
@export var time_to_next_input : float

var is_finished : bool
