extends PanelContainer

signal press(slot)
signal present(slot)

onready var index_buttons = $VBoxContainer/Index
onready var index_template = $VBoxContainer/IndexTemplate
onready var input_buttons = $VBoxContainer/Input
onready var chat = $VBoxContainer/Chatline


var statements = []
var current_slot = 0

func _ready():
	var avatar = load("res://avatars/guy.png")
	add_statement("This is testimony 1", "Bob", avatar)
	add_statement("This is statement 2", "Bob", avatar)
	add_statement("This is statement 3, the final statement", "Bob", avatar)
	play_statement(current_slot)

func add_statement(dialog, speaker, avatar):
	statements.append({"dialog": dialog, "speaker": speaker, "avatar": avatar})
	_add_index_button()

func play_statement(slot: int):
	current_slot = slot
	var statement = statements[current_slot]
	chat.display_text(statement["dialog"], statement["speaker"], statement["avatar"])
	set_index_button(current_slot)

func _on_left_pressed():
	if current_slot - 1 < 0:
		return
	play_statement(current_slot - 1)

func _on_right_pressed():
	if current_slot + 1 >= statements.size():
		return
	play_statement(current_slot + 1)

func _add_index_button():
	var option = index_template.duplicate()
	index_buttons.add_child(option)
	var i = option.get_index()
	option.set_text(String(i+1))
	option.set_visible(true)
	option.connect("pressed", self, "_on_index_button_pressed", [i])

func _on_index_button_pressed(slot: int):
	if slot == current_slot:
		return
	play_statement(slot)

func set_index_button(slot: int):
	for child in index_buttons.get_children():
		child.set_pressed(false)
		child.mouse_filter = MOUSE_FILTER_PASS
	var option = index_buttons.get_child(slot)
	option.set_pressed(true)
	option.mouse_filter = MOUSE_FILTER_IGNORE
