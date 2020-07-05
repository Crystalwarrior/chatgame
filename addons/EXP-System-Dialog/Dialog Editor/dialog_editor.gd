tool
extends Control

signal back_BTN_pressed
signal close_BTN_pressed

onready var _Graph = get_node("VBoxContainer/GraphEdit")
onready var _Human_Readable_LBL = get_node("VBoxContainer/VBoxContainer/Human_Readable_LBL")

var _Editor_TSCN = preload("res://addons/EXP-System-Dialog/Dialog Editor/Editor/Editor.tscn")
var _LineNode = preload("res://addons/EXP-System-Dialog/Dialog Editor/Nodes/Line/Line_Node.tscn")
var _NodeTemplate= preload("res://addons/EXP-System-Dialog/Resource_NodeTemplate/EXP_NodeTemplate.gd")

var _did : int = -1
var _Editor
var _Load_Template : EditorFileDialog
var _Save_Template_As : EditorFileDialog
var _Story_Editor
var _Target_Node

#Virtual Methods

func _ready():
	_setup_dialogs()
	_Editor = _Editor_TSCN.instance()
	add_child(_Editor)

#Callback Methods

func _on_Add_Node_BTN_pressed():
	var new_nid = _Story_Editor.create_node(_did, "line")
	var new_line_node = _LineNode.instance()
	new_line_node.offset += _Graph.scroll_offset
	new_line_node.set_nid(new_nid)
	new_line_node.connect("erased", self, "_on_Node_erased")
	new_line_node.connect("changed_offset", self, "_on_Node_changed_offset")
	new_line_node.connect("text_changed", self, "_on_Node_text_changed")
	new_line_node.connect("pressed_save", self, "_on_Node_pressed_save")
	new_line_node.connect("pressed_load", self, "_on_Node_pressed_load")
	new_line_node.connect("pressed_editor", self, "_on_Node_pressed_editor")
	new_line_node.connect("changed_slots", self, "_on_Node_changed_slots")
	new_line_node.connect("changed_size", self, "_on_Node_changed_size")
	var slot_count = _Story_Editor.get_node_property(_did, new_nid, "slot_amount")
	_Story_Editor.set_node_property(_did, new_nid, "rect_size", new_line_node.rect_size)
	new_line_node.set_slot_amount(slot_count)
	_Graph.add_child(new_line_node)


func _on_Back_BTN_pressed():
	emit_signal("back_BTN_pressed")


func _on_Close_BTN_pressed():
	emit_signal("close_BTN_pressed")


func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	_Graph.connect_node(from, from_slot, to, to_slot)
	var from_node = _Graph.get_node(from)
	var to_node = _Graph.get_node(to)
	var from_node_nid = from_node.get_nid()
	var to_node_nid = to_node.get_nid()
	_Story_Editor.set_link(_did, from_node_nid, from_slot, to_node_nid)


func _on_GraphEdit_disconnection_request(from, from_slot, to, to_slot):
	_Graph.disconnect_node(from, from_slot, to, to_slot)
	var from_node = _Graph.get_node(from)
	var from_node_nid = from_node.get_nid()
	_Story_Editor.erase_link(_did, from_node_nid, from_slot)


func _on_Load_Template_file_selected(filename):
	var file_data = load(filename)
	if not file_data.TYPE == "EXP_Dialog_Node_Template_editor":
		return
	
	_Target_Node.set_text(file_data.template)


func _on_Node_changed_offset(nid, new_offset):
	_Story_Editor.set_node_property(_did, nid, "graph_offset", new_offset)


func _on_Node_changed_size(changed_node):
	var changed_node_nid = changed_node.get_nid()
	_Story_Editor.set_node_property(_did, changed_node_nid, "rect_size", changed_node.rect_size)


func _on_Node_changed_slots(changed_node):
	var changed_node_nid = changed_node.get_nid()
	_unlink_nid_from_story(changed_node_nid)
	_disconnect_all_from(changed_node)
	_Story_Editor.set_node_property(_did, changed_node_nid, "slot_amount",
		changed_node.get_slot_amount())


func _on_Node_erased(deleted_node):
	var deleted_nid = deleted_node.get_nid()
	_unlink_nid_from_story(deleted_nid)
	_Story_Editor.erase_node(_did, deleted_nid)
	_disconnect_all_from(deleted_node)
	deleted_node.queue_free()


func _on_Node_pressed_editor(node):
	_Editor.set_target_node(node)
	_Editor.visible = true


func _on_Node_pressed_load(node):
	_Target_Node = node
	_Load_Template.popup_centered_ratio(0.7)


func _on_Node_pressed_save(node):
	_Target_Node = node
	_Save_Template_As.popup_centered_ratio(0.7)


func _on_Node_text_changed(nid, new_text):
	_Story_Editor.set_node_property(_did, nid, "text", new_text)


func _on_Save_Template_As_file_selected(filename):
	var save_file = _NodeTemplate.new()
	save_file.template = _Target_Node.get_text()
	ResourceSaver.save(filename, save_file)


func _on_Story_Editor_dialog_edit_pressed(story_editor, did : int):
	_Story_Editor = story_editor
	_did = did
	_Human_Readable_LBL.text = _Story_Editor.get_dialog_property(_did, "human_readable_description")
	_clear_nodes()
	_populate_graph()
	_link_node_connections()

#Private Methods

func _clear_nodes():
	_Graph.clear_connections()
	var children = _Graph.get_children()
	for child in children:
		if child is GraphNode:
			child.free()


func _disconnect_all_from(node):
	var node_name = node.name
	var connection_list = _Graph.get_connection_list()
	for connection in connection_list:
		if connection["from"] == node.name or connection["to"] == node.name:
			_Graph.disconnect_node(connection["from"], connection["from_port"],
				connection["to"], connection["to_port"])


func _link_node_connections():
	var node_IDs = _Story_Editor.get_nids(_did)
	for nID in node_IDs:
		var slots = _Story_Editor.get_link_slots(_did, nID)
		for slot in slots:
			var to_node_nid = _Story_Editor.get_nid_link_from(_did, nID, slot)
			var to = "NID " + str(to_node_nid)
			var from = "NID " + str(nID)
			_Graph.connect_node(from, slot, to, 0)


func _populate_graph():
	var node_IDs = _Story_Editor.get_nids(_did)
	for nID in node_IDs:
		var new_node : GraphNode
		match _Story_Editor.get_node_property(_did, nID, "type"):
			"line":
				new_node = _LineNode.instance()
				var slot_count = _Story_Editor.get_node_property(_did, nID, "slot_amount")
				new_node.set_slot_amount(slot_count)
				_Graph.add_child(new_node)
				new_node.connect("erased", self, "_on_Node_erased")
				var new_text = _Story_Editor.get_node_property(_did, nID, "text")
				var new_rect_size = _Story_Editor.get_node_property(_did, nID, "rect_size")
				new_node.rect_size = new_rect_size
				new_node.set_text(new_text)
				new_node.connect("text_changed", self, "_on_Node_text_changed")
				new_node.connect("pressed_save", self, "_on_Node_pressed_save")
				new_node.connect("pressed_load", self, "_on_Node_pressed_load")
				new_node.connect("pressed_editor", self, "_on_Node_pressed_editor")
				new_node.connect("changed_slots", self, "_on_Node_changed_slots")
				new_node.connect("changed_size", self, "_on_Node_changed_size")
		
		new_node.set_nid(nID)
		new_node.offset = _Story_Editor.get_node_property(_did, nID, "graph_offset")
		new_node.connect("changed_offset", self, "_on_Node_changed_offset")


func _setup_dialogs():
	_Load_Template = EditorFileDialog.new()
	_Load_Template.mode = EditorFileDialog.MODE_OPEN_FILE
	_Load_Template.add_filter("*.res ; Template files")
	_Load_Template.resizable = true
	_Load_Template.access = EditorFileDialog.ACCESS_RESOURCES
	_Load_Template.current_dir = "res://"
	_Load_Template.connect("file_selected", self, "_on_Load_Template_file_selected")
	add_child(_Load_Template)
	
	_Save_Template_As = EditorFileDialog.new()
	_Save_Template_As.mode = EditorFileDialog.MODE_SAVE_FILE
	_Save_Template_As.add_filter("*.res ; Template files")
	_Save_Template_As.resizable = true
	_Save_Template_As.access = EditorFileDialog.ACCESS_RESOURCES
	_Save_Template_As.current_dir = "res://"
	_Save_Template_As.connect("file_selected", self, "_on_Save_Template_As_file_selected")
	add_child(_Save_Template_As)


func _unlink_nid_from_story(removed_nid):
	_Story_Editor.erase_all_links(_did, removed_nid)
	var nIDs = _Story_Editor.get_nids(_did)
	for nID in nIDs:
		var node_slots = _Story_Editor.get_link_slots(_did, nID)
		for slot in node_slots:
			var to_node_nid = _Story_Editor.get_nid_link_from(_did, nID, slot)
			if to_node_nid == removed_nid:
				_Story_Editor.erase_link(_did, nID, slot)
