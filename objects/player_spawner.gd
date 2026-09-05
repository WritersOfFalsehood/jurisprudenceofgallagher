@tool
extends Node2D
class_name PlayerSpawner

@export_enum("Left", "Right") var direction : int = 1


func _ready() -> void:
	direction = direction * 2 - 1
	if !Engine.is_editor_hint():
		visible = false


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		var default_font : Font = Control.new().get_theme_font("font")
		
		var text : String = str(get_index())
		var font_size : int = 24
		var text_color : Color = Color.WHITE
		
		# 3. Draw the string
		draw_string(default_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
