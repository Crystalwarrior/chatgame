extends PanelContainer

export var min_chars = 1
export var max_chars = 24

onready var input_bar = $HBoxContainer/LineEdit
onready var send_button = $HBoxContainer/Button

var text = ""

signal entered(text)

func _ready():
	input_bar.set_max_length(max_chars)

func _on_LineEdit_text_changed(new_text):
	text = new_text
	if validate_text():
		send_button.set_disabled(false)
	else:
		send_button.set_disabled(true)

func _on_LineEdit_text_entered(new_text):
	text = new_text
	if validate_text():
		send_entered()

func _on_Button_pressed():
	if validate_text():
		send_entered()

func validate_text():
	return text.length() >= min_chars and text.length() <= max_chars

func send_entered():
	input_bar.set_editable(false)
	send_button.set_disabled(true)
	emit_signal("entered", text)
