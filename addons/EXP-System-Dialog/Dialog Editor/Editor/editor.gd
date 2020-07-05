tool
extends WindowDialog

onready var _Text_Editor = get_node("VBoxContainer/TextEdit")

var _Target_Node

#Public Methods

func set_target_node(node):
	_Target_Node = node
	_Text_Editor.text = node.get_text()

#Callback Methods

func _on_OK_BTN_pressed():
	visible = false


func _on_TextEdit_text_changed():
	_Target_Node.set_text(_Text_Editor.text)
