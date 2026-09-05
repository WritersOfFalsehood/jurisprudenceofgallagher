extends CanvasLayer

@export var choice_box_selection : PackedScene

@onready var control = $Control

@onready var portrait_image = $Control/MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/Portrait
@onready var character_text_label = $Control/MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/VBoxContainer/CharacterText
@onready var text_label = $Control/MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/VBoxContainer/BodyText
@onready var next_arrow = $Control/MarginContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/NextArrow

@onready var choice_box = $Control/MarginContainer/VBoxContainer/PanelContainer
@onready var choice_box_container = $Control/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer

@onready var letter_tick_timer = $LetterTickTimer

var current_dialogue_item : DialogueItem
var next_character : String
var text_index : int
var is_finished : bool
var choice_index : int

var portrait_minimum_size : float
var character_text_minimum_size : float

const LETTER_TIME = 0.04
const PUNC_LETTER_TIME = 0.4
var PUNC_LETTERS = ".,:;!?"


func _ready():
	visible = false
	
	portrait_minimum_size = portrait_image.custom_minimum_size.x
	character_text_minimum_size = character_text_label.custom_minimum_size.y
	


func _process(delta):
	Global.is_talking = visible
	
	if visible:
		portrait_image.custom_minimum_size = Vector2.ONE * 1 if current_dialogue_item.portrait == null else Vector2.ONE * portrait_minimum_size
		character_text_label.custom_minimum_size.y = 0 if character_text_label.text.length() == 0 else character_text_minimum_size
	
	#choice box stuff and also manage the cursor
	if current_dialogue_item:
		choice_box.visible = current_dialogue_item is DialogueChoice and is_finished
	
	var i = 0
	for selection in choice_box_container.get_children():
		selection.is_selected = choice_index == i
		i += 1
	
	
	if is_finished:
		text_label.visible_characters = -1
		next_arrow.texture.pause = false
	else:
		next_arrow.texture.current_frame = 1
		next_arrow.texture.pause = true


func letter_tick():
	if !is_finished:
		next_character = current_dialogue_item.character_text[text_index]
		
		#skip formatting parts
		if next_character == "[":
			while next_character != "]":
				next_character = current_dialogue_item.character_text[text_index]
				text_index += 1
		
		text_label.visible_characters += 1
		text_index += 1
		
		if text_index >= current_dialogue_item.character_text.length():
			is_finished = true
			return
		
		letter_tick_timer.start(PUNC_LETTER_TIME if next_character in PUNC_LETTERS else LETTER_TIME)


func initialise(dialogue_item : DialogueItem):
	current_dialogue_item = dialogue_item
	
	character_text_label.text = current_dialogue_item.character_name
	text_label.text = current_dialogue_item.character_text.strip_edges(true, false)
	portrait_image.texture = current_dialogue_item.portrait
	
	text_label.visible_characters = 0
	text_index = 0
	is_finished = false
	
	# reset choice and put in new option text
	if current_dialogue_item is DialogueChoice:
		choice_index = 0
		
		for selection in choice_box_container.get_children():
			selection.queue_free()
		
		for text in current_dialogue_item.selections:
			var choice = choice_box_selection.instantiate()
			choice.text = text
			choice_box_container.add_child(choice)
	
	letter_tick()


func _input(event):
	if current_dialogue_item:
		if (event.is_action_pressed("Dialogue Advance") or event.is_action_pressed("Dialogue Back")) and current_dialogue_item.active:
			if is_finished:
				if current_dialogue_item is DialogueChoice:
					current_dialogue_item.return_choice(choice_index)
				current_dialogue_item.deactivate()
			else:
				is_finished = true
		
		if current_dialogue_item is DialogueChoice:
			if is_finished:
				if event.is_action_pressed("Up"):
					choice_index = max(0, choice_index - 1)
				if event.is_action_pressed("Down"):
					choice_index = min(choice_box_container.get_children().size() - 1, choice_index + 1)
