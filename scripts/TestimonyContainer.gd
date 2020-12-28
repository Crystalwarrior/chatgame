extends PanelContainer

signal press(nid)
signal present(nid)

onready var index_buttons = $VBoxContainer/Index
onready var index_template = $VBoxContainer/IndexTemplate
onready var input_buttons = $VBoxContainer/Input
onready var chat = $VBoxContainer/Chatline


var statements = []
var current_slot = 0

func _ready():
	var avatar = load("res://avatars/guy.png")

func add_statement(dialog, speaker, avatar, nid, can_press=true, can_present=true):
	statements.append(
		{
			"dialog": dialog, "speaker": speaker, "avatar": avatar, "nid": nid,
			"can_press": can_press, "can_present": can_present
		}
	)
	_add_index_button()

func play_statement(slot: int):
	current_slot = slot
	var statement = statements[current_slot]
	chat.display_text(
		statement["dialog"], statement["speaker"], statement["avatar"]
	)
	input_buttons.get_node("press").set_disabled(!statement["can_press"])
	input_buttons.get_node("present").set_disabled(!statement["can_present"])
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

func disable():
	for button in input_buttons.get_children():
		button.set_disabled(true)
	for button in index_buttons.get_children():
		button.set_disabled(true)


func _on_press_pressed():
	emit_signal("press", statements[current_slot]["nid"])
	disable()


func _on_present_pressed():
	emit_signal("present", statements[current_slot]["nid"])
