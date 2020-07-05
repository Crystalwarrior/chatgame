tool
extends EditorPlugin

var _Story_Editor = preload("res://addons/EXP-System-Dialog/Story Editor/Story_Editor.tscn")
var _Story_Editor_Instance
var _Story_Editor_BTN : ToolButton
var _Dialog_Editor = preload("res://addons/EXP-System-Dialog/Dialog Editor/Dialog_Editor.tscn")
var _Dialog_Editor_Instance
var _Dialog_Editor_BTN : ToolButton


func _enter_tree():
	
	_Story_Editor_Instance = _Story_Editor.instance()
	_Story_Editor_Instance.connect("close_pressed", self, "_on_StoryFile_Editor_close_pressed")
	_Story_Editor_BTN = add_control_to_bottom_panel(_Story_Editor_Instance, "EXP StoryFile Editor")
	_Story_Editor_Instance.visible = false
	_Story_Editor_BTN.visible = false
	add_tool_menu_item("EXP StoryFile Editor", self, "_on_StoryFile_Editor_opened")
	
	_Dialog_Editor_Instance = _Dialog_Editor.instance()
	_Dialog_Editor_BTN = add_control_to_bottom_panel(_Dialog_Editor_Instance, "EXP Dialog Editor")
	_Dialog_Editor_BTN.visible = false
	
	_Story_Editor_Instance.connect("dialog_edit_pressed",
		self, "_on_Story_Editor_dialog_edit_pressed")
	_Story_Editor_Instance.connect("dialog_edit_pressed",
		_Dialog_Editor_Instance, "_on_Story_Editor_dialog_edit_pressed")
	_Dialog_Editor_Instance.connect("close_BTN_pressed", self,
		"_on_Dialog_Editor_close_BTN_pressed")
	_Dialog_Editor_Instance.connect("back_BTN_pressed", self,
		"_on_Dialog_Editor_back_BTN_pressed")
	_Story_Editor_Instance.connect("changed_story", self,
		"_on_Story_Editor_changed_story")
	
	
func _exit_tree():
	
	_Story_Editor_Instance.disconnect("dialog_edit_pressed",
		self, "_on_Story_Editor_dialog_edit_pressed")
	_Story_Editor_Instance.disconnect("dialog_edit_pressed",
		_Dialog_Editor_Instance, "_on_Story_Editor_dialog_edit_pressed")
	_Dialog_Editor_Instance.disconnect("close_BTN_pressed", self,
		"_on_Dialog_Editor_close_BTN_pressed")
	_Dialog_Editor_Instance.disconnect("back_BTN_pressed", self,
		"_on_Dialog_Editor_back_BTN_pressed")
	_Story_Editor_Instance.disconnect("changed_story", self,
		"_on_Story_Editor_changed_story")
		
	remove_control_from_bottom_panel(_Story_Editor_Instance)
	_Story_Editor_Instance.queue_free()
	remove_control_from_bottom_panel(_Dialog_Editor_Instance)
	_Dialog_Editor_Instance.queue_free()
	remove_tool_menu_item("EXP StoryFile Editor")


func _on_Story_Editor_dialog_edit_pressed(story, did):
	_Dialog_Editor_BTN.visible = true
	_Story_Editor_BTN.pressed = false
	_Dialog_Editor_BTN.pressed = true
	_Dialog_Editor_BTN.emit_signal("pressed")


func _on_Dialog_Editor_close_BTN_pressed():
	_Dialog_Editor_BTN.pressed = false
	_Dialog_Editor_BTN.visible = false


func _on_Story_Editor_changed_story():
	_Dialog_Editor_BTN.visible = false


func _on_Dialog_Editor_back_BTN_pressed():
	_Story_Editor_BTN.pressed = true
	_Dialog_Editor_BTN.pressed = false
	_Story_Editor_BTN.emit_signal("pressed")


func _on_StoryFile_Editor_opened(trash_parameter):
	_Story_Editor_BTN.visible = true


func _on_StoryFile_Editor_close_pressed():
	_Story_Editor_Instance.visible = false
	_Story_Editor_BTN.visible = false
	_Dialog_Editor_Instance.visible = false
	_Dialog_Editor_BTN.visible = false
