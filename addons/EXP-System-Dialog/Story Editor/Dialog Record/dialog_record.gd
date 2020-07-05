tool
extends Control

signal changed_human_readable_text(did, text)
signal checked(this)
signal edit_pressed(did)
signal rename_pressed(this)
signal unchecked(this)

onready var _DID_LBL = get_node("ColorRect/HBoxContainer/DID_LBL")
onready var _Human_Readable_LineEdit = get_node("ColorRect/HBoxContainer/Human_Readable_LineEdit")
onready var _Group_List = get_node("ColorRect/HBoxContainer/Group_BTN")
onready var _Name_BTN = get_node("ColorRect/HBoxContainer/Name_BTN")
onready var _Select_CheckBox = get_node("ColorRect/HBoxContainer/CheckBox")

var _did : int = -1
var _Story_Editor

#Virtual Methods

func _ready():
	update_human_readable_description("Human Readable Description")

#Callback Methods

func _on_CheckBox_toggled(button_pressed):
	if button_pressed:
		emit_signal("checked", self)
	else:
		emit_signal("unchecked", self)


func _on_Edit_BTN_pressed():
	emit_signal("edit_pressed", _did)


func _on_Group_BTN_pressed():
	var groups = _Story_Editor.dialog_get_groups(_did)
	_Group_List.clear()
	_Group_List.text = "TAGS"
	for group in groups:
		_Group_List.get_popup().add_item(group)
	for idx in range(_Group_List.get_item_count()):
		_Group_List.set_item_disabled(idx, true)


func _on_Human_Readable_LineEdit_focus_exited():
	_Human_Readable_LineEdit.deselect()


func _on_Human_Readable_LineEdit_text_changed(new_text):
	emit_signal("changed_human_readable_text", _did, new_text)


func _on_Name_BTN_pressed():
	emit_signal("rename_pressed", self)

#Public Methods

func check():
	_Select_CheckBox.pressed = true


func get_did():
	return _did


func get_record_name():
	return _Name_BTN.text


func set_did(new_did : int):
	_did = new_did
	_DID_LBL.text = "DID: " + str(new_did)


func set_record_name(rename : String):
	_Name_BTN.text = rename


func set_story_editor(editor):
	_Story_Editor = editor


func uncheck():
	_Select_CheckBox.pressed = false


func update_human_readable_description(new_text):
	_Human_Readable_LineEdit.text = new_text
	emit_signal("changed_human_readable_text", _did, new_text)
