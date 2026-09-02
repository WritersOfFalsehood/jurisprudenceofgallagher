extends HBoxContainer

@onready var cursor = $TextureRect
@onready var text_box = $RichTextLabel

var text : String
var is_selected : bool


func _process(delta):
	text_box.text = text
	cursor.modulate.a = 1 if is_selected else 0
