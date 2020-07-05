tool
extends WindowDialog

signal rename_BTN_pressed(text)

onready var _Name_LineEdit = get_node("MarginContainer/VBoxContainer/Name_LineEdit")

var _Target_Record = null

#Public Methods

func get_target_record():
	return _Target_Record


func set_target_record(record):
	_Target_Record = record
	_Name_LineEdit.text = record.get_record_name()

#Callback Methods

func _on_Cancel_BTN_pressed():
	visible = false


func _on_Rename_BTN_pressed():
	visible = false
	emit_signal("rename_BTN_pressed", _Name_LineEdit.text)


func _on_Name_LineEdit_text_entered(new_text):
	_on_Rename_BTN_pressed()
