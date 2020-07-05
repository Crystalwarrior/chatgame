tool
extends Control

signal changed_story
signal close_pressed
signal dialog_edit_pressed(story, did)

onready var _Dialog_Record_Root = get_node("VBoxContainer/HBoxContainer3/Panel/VScrollBar/Dialog_Record_Root")
onready var _Dir = Directory.new()
onready var _Filename_LBL = get_node("VBoxContainer/HBoxContainer2/Filename_LBL")
onready var _Filter_Menu = get_node("VBoxContainer/HBoxContainer2/Filter_MenuButton")
onready var _Group_List = get_node("VBoxContainer/HBoxContainer3/Group_Manager/Group_ItemList")
onready var _Group_Manager_Panel = get_node("VBoxContainer/HBoxContainer3/Group_Manager")
onready var _Group_Selector = get_node("VBoxContainer/HBoxContainer/Group_Selector_BTN")
onready var _New_Group_LineEdit = get_node("VBoxContainer/HBoxContainer3/Group_Manager/HBoxContainer/Add_Group_LineEdit")
onready var _Search_LineEdit = get_node("VBoxContainer/HBoxContainer2/Search_LineEdit")
onready var _Search_Option_BTN = get_node("VBoxContainer/HBoxContainer2/Search_OptionButton")
onready var _Story_Menu = get_node("VBoxContainer/HBoxContainer/Story")

var _Dialog_Record = preload("res://addons/EXP-System-Dialog/Story Editor/Dialog Record/Dialog_Record.tscn")
var _EXP_Baked_Story = preload("res://addons/EXP-System-Dialog/Resource_BakedStory/EXP_BakedStory.gd")
var _EXP_Story = preload("res://addons/EXP-System-Dialog/Resource_EditorStory/EXP_EditorStory.gd")
var _Record_Rename_Box_TSCN = preload("res://addons/EXP-System-Dialog/Story Editor/Rename Record Box/Rename_Record_Box.tscn")

var _available_dids : Array
var _Bake_Story_As : EditorFileDialog
var _checked_dialogs : Array = []
var _groups : Array
var _Load_CSV : EditorFileDialog
var _Load_Story : EditorFileDialog
var _record_names : Dictionary
var _Record_Rename_Box
var _Save_CSV_As : EditorFileDialog
var _Save_Story_As : EditorFileDialog
var _story : Dictionary

#Virtual Methods

func _ready():
	_create_rename_box()
	_populate_story_menu()
	_setup_dialogs()
	_Filter_Menu.get_popup().connect("index_pressed", self, "_on_Filter_Menu_index_pressed")
	_Filter_Menu.get_popup().hide_on_checkable_item_selection = false
	_populate_filter_menu()
	_populate_searchby_menu()

#Callback Methods

func _on_Add_Group_BTN_pressed():
	_add_group()


func _on_Add_Group_LineEdit_text_entered(new_text):
	_add_group()


func _on_Apply_Group_BTN_pressed():
	var id = _Group_Selector.get_selected_id()
	if id == -1:
		return
	
	var idx = _Group_Selector.get_item_index(id)
	var group = _Group_Selector.get_popup().get_item_text(idx)
	for record in _checked_dialogs.duplicate():
		var did = record.get_did()
		_dialog_apply_group(did, group)
		record.uncheck()
	emit_signal("changed_story")


func _on_Bake_Story_As_file_selected(filename : String):
	_bake_data_to(filename)


func _on_Bake_Story_BTN_pressed():
	_Bake_Story_As.popup_centered_ratio(0.7)


func _on_Check_All_BTN_pressed():
	var records = _Dialog_Record_Root.get_children()
	for record in records:
		if record.visible:
			record.check()


func _on_Close_BTN_pressed():
	emit_signal("close_pressed")


func _on_Create_Dialog_BTN_pressed():
	_create_dialog_record()


func _on_Delete_Dialog_BTN_pressed():
	_delete_checked_dialogs()


func _on_Delete_Group_BTN_pressed():
	var idxs = _Group_List.get_selected_items()
	var group
	for idx in idxs:
		group = _Group_List.get_item_text(idx)
		_Group_List.remove_item(idx)
		_delete_group(group)
	_populate_group_selector()
	_populate_filter_menu()
	

func _on_Dialog_changed_human_readable_text(did : int, new_text : String):
	set_dialog_property(did, "human_readable_description", new_text)
	emit_signal("changed_story")


func _on_Dialog_checked(dialog):
	_checked_dialogs.push_front(dialog)


func _on_Dialog_edit_pressed(did : int):
	emit_signal("dialog_edit_pressed", self, did)


func _on_Dialog_unchecked(dialog):
	_checked_dialogs.erase(dialog)


func _on_Filter_Menu_index_pressed(idx):
	var checked = _Filter_Menu.get_popup().is_item_checked(idx)
	if not checked:
		_Filter_Menu.get_popup().set_item_checked(idx, true)
	else:
		_Filter_Menu.get_popup().set_item_checked(idx, false)
	_update_filter()


func _on_Group_Manager_BTN_toggled(button_pressed : bool):
	if button_pressed:
		_Group_Manager_Panel.visible = true
	else:
		_Group_Manager_Panel.visible = false


func _on_Group_Selector_BTN_pressed():
	_populate_group_selector()


func _on_Load_CSV_BTN_pressed():
	_Load_CSV.popup_centered_ratio(0.7)


func _on_Load_CSV_file_selected(filepath : String):
	var csv_file = File.new()
	var status = csv_file.open(filepath, File.READ)
	
	if not status == OK:
		print_debug("EXP_Story_Editor: Error loading file \"" + filepath + "\".")
		return
	
	csv_file.get_csv_line()
	
	while not csv_file.eof_reached():
		var line = csv_file.get_csv_line()
		
		if line.empty():
			continue
		
		var did = int(line[0])
		var nid = int(line[1])
		var dialog = String(line[2])
		
		if not _story.has(did):
			continue
		if not _story[did]["nodes"].has(nid):
			continue
		
		_story[did]["nodes"][nid]["text"] = dialog
	
	csv_file.close()


func _on_Load_Story_BTN_pressed():
	_Load_Story.popup_centered_ratio(0.7)


func _on_Load_Story_file_selected(filename : String):
	var file_data = load(filename)
	if not file_data.TYPE == "EXP_Story_editor":
		return
	
	_clear_story()
	_load_data_from(file_data)
	_Filename_LBL.text = filename.get_file()
	
	for group in _groups:
		_Group_List.add_item(group)
	_populate_filter_menu()
	
	for did in get_dids():
		var new_dialog_record = _Dialog_Record.instance()
		_Dialog_Record_Root.add_child(new_dialog_record)
		new_dialog_record.set_story_editor(self)
		new_dialog_record.connect("checked", self, "_on_Dialog_checked")
		new_dialog_record.connect("unchecked", self, "_on_Dialog_unchecked")
		new_dialog_record.connect("changed_human_readable_text", self,
			"_on_Dialog_changed_human_readable_text")
		new_dialog_record.connect("edit_pressed", self, "_on_Dialog_edit_pressed")
		new_dialog_record.connect("rename_pressed", self, "_on_Record_Rename_pressed")
		
		new_dialog_record.set_did(did)
		var human_readable_description = get_dialog_property(did, "human_readable_description")
		new_dialog_record.update_human_readable_description(human_readable_description)
		
		if _story[did].has("name"):
			var record_name = _story[did]["name"]
			new_dialog_record.set_record_name(record_name)


func _on_New_Story_BTN_pressed():
	_clear_story()


func _on_Record_Rename_pressed(record):
	_Record_Rename_Box.set_target_record(record)
	_Record_Rename_Box.visible = true


func _on_Remove_Group_BTN_pressed():
	var id = _Group_Selector.get_selected_id()
	if id == -1:
		return
		
	var idx = _Group_Selector.get_item_index(id)
	var group = _Group_Selector.get_popup().get_item_text(idx)
	for record in _checked_dialogs.duplicate():
		var did = record.get_did()
		_dialog_remove_group(did, group)
		record.uncheck()
	emit_signal("changed_story")


func _on_Rename_Box_Rename(rename : String):
	var record = _Record_Rename_Box.get_target_record()
	var old_name = record.get_record_name()
	var record_did = record.get_did()
	
	if rename.empty() or rename == "NAME":
		record.set_record_name("NAME")
		_story[record_did].erase("name")
		_record_names.erase(old_name)
		return
	
	if _record_names.has(rename):
		return
	
	_record_names.erase(old_name)
	
	_record_names[rename] = record_did
	_story[record_did]["name"] = rename
	record.set_record_name(rename)


func _on_Save_CSV_BTN_pressed():
	_Save_CSV_As.popup_centered_ratio(0.7)


func _on_Save_CVS_As_file_selected(filepath : String):
	var csv_file = File.new()
	var status = csv_file.open(filepath, File.WRITE)
	
	if not status == OK:
		print_debug("EXP_Story_Editor: Error saving csv file \"" + filepath + "\".")
		return
	
	csv_file.store_csv_line(["DID", "NID", "Dialog"], ",")
	
	for did in _story.keys():
		for nid in _story[did]["nodes"].keys():
			var dialog = _story[did]["nodes"][nid]["text"]
			csv_file.store_csv_line([did, nid, dialog], ",")
	
	csv_file.close()


func _on_Save_Story_As_file_selected(filename : String):
	_save_data_to(filename)
	_Filename_LBL.text = filename.get_file()


func _on_Save_Story_BTN_pressed():
	_Save_Story_As.popup_centered_ratio(0.7)


func _on_Search_LineEdit_text_changed(new_text : String):
	_update_filter()


func _on_Search_OptionButton_item_selected(id):
	_update_filter()


func _on_story_menu_option_pressed(id):
	match id:
		0:
			_on_New_Story_BTN_pressed()
		1:
			_on_Load_Story_BTN_pressed()
		2:
			_on_Save_Story_BTN_pressed()
		3:
			_on_Bake_Story_BTN_pressed()
		4:
			_on_Save_CSV_BTN_pressed()
		5:
			_on_Load_CSV_BTN_pressed()


func _on_Uncheck_All_BTN_pressed():
	var records = _Dialog_Record_Root.get_children()
	for record in records:
		if record.visible:
			record.uncheck()

#Public Methods

func create_node(did : int, type : String) -> int:
	var new_nid = _generate_nid(did)
	var node_data = {"type": type, "text": "", "graph_offset": Vector2(40, 40),
	"rect_size": Vector2(0,0) ,"links": {}, "slot_amount": 1}
	_story[did]["nodes"][new_nid] = node_data
	return new_nid

func dialog_get_groups(did : int):
	return _story[did]["groups"]


func erase_all_links(did: int, nid : int):
	_story[did]["nodes"][nid]["links"].clear()


func erase_dialog(did : int):
	_story.erase(did)
	_make_did_available(did)


func erase_link(did : int, nid : int, slot : int):
	_story[did]["nodes"][nid]["links"].erase(slot)


func erase_node(did :int, nid :int):
	_story[did]["nodes"].erase(nid)
	_make_nid_available(did, nid)


func get_dialog_property(did : int, property: String):
	return _story[did][property]


func get_dids():
	return _story.keys()


func get_link_slots(did : int, nid : int):
	return _story[did]["nodes"][nid]["links"].keys()


func get_nid_link_from(did : int, nid: int, slot : int):
	return _story[did]["nodes"][nid]["links"][slot]


func get_nids(did : int):
	return _story[did]["nodes"].keys()


func get_node_property(did : int, nid : int, property: String):
	return _story[did]["nodes"][nid][property]


func set_dialog_property(did : int, property : String , data):
	_story[did][property] = data


func set_link(did : int, this_nid : int, slot : int, that_nid : int):
	_story[did]["nodes"][this_nid]["links"][slot] = that_nid


func set_node_property(did : int, nid : int, property : String , data):
	_story[did]["nodes"][nid][property] = data


func set_node_slot_count(did : int, nid : int, amount : int):
	_story[did]["nodes"][nid]["slot_amount"] = amount

#Private Methods

func _add_group():
	var new_group_name = _New_Group_LineEdit.text
	if new_group_name == "" or _groups.has(new_group_name):
		return
	
	_groups.push_back(new_group_name)
	_New_Group_LineEdit.text = ""
	_Group_List.add_item(new_group_name)
	_populate_filter_menu()
	
	var sort_list : Array
	for idx in range(_Group_List.get_item_count()):
		var group = _Group_List.get_item_text(idx)
		sort_list.push_back(group)
	sort_list.sort()
	_Group_List.clear()
	for group in sort_list:
		_Group_List.add_item(group)


func _bake_data() :
	var baked_story = _story.duplicate(true)
	for did in baked_story.keys():
		baked_story[did].erase("name")
		baked_story[did].erase("groups")
		baked_story[did].erase("available_nid")
		baked_story[did].erase("human_readable_description")
		for nid in baked_story[did]["nodes"].keys():
			baked_story[did]["nodes"][nid].erase("type")
			baked_story[did]["nodes"][nid].erase("graph_offset")
			baked_story[did]["nodes"][nid].erase("rect_size")
			baked_story[did]["nodes"][nid].erase("slot_amount")
	return baked_story.duplicate(true)


func _bake_data_to(filename):
	var file_data
	if _Dir.file_exists(filename):
		file_data = load(filename)
		if file_data.TYPE == "EXP_Baked_Story":
			file_data.story = _bake_data()
			file_data.names = _record_names.duplicate(true)
			ResourceSaver.save(filename, file_data)
	else:
		file_data = _EXP_Baked_Story.new()
		file_data.story = _bake_data()
		file_data.names = _record_names.duplicate(true)
		ResourceSaver.save(filename, file_data)


func _clear_group_manager():
	_groups.clear()
	for idx in range(_Group_List.get_item_count()):
		_Group_List.remove_item(0)
		_populate_group_selector()
		_Filter_Menu.get_popup().clear()


func _clear_story():
	_remove_all_records()
	_clear_group_manager()
	_populate_filter_menu()
	_story.clear()
	_available_dids.clear()
	_checked_dialogs.clear()
	_record_names.clear()
	_Filename_LBL.text = "Unsaved Story"
	emit_signal("changed_story")


func _create_dialog() -> int:
	var new_did = _generate_did()
	var dialog_data = {"human_readable_description":
		"New Dialog - Enter Human Readable Description",
		"groups": [],
		"available_nid": [],
		"nodes": {}}
	_story[new_did] = dialog_data
	return new_did


func _create_dialog_record():
	var new_did = _create_dialog()
	
	var new_dialog_record = _Dialog_Record.instance()
	_Dialog_Record_Root.add_child(new_dialog_record)
	new_dialog_record.set_story_editor(self)
	
	new_dialog_record.connect("checked", self, "_on_Dialog_checked")
	new_dialog_record.connect("unchecked", self, "_on_Dialog_unchecked")
	new_dialog_record.connect("changed_human_readable_text", self,
		"_on_Dialog_changed_human_readable_text")
	new_dialog_record.connect("edit_pressed", self, "_on_Dialog_edit_pressed")
	new_dialog_record.connect("rename_pressed", self, "_on_Record_Rename_pressed")
	
	new_dialog_record.set_did(new_did)
	new_dialog_record.update_human_readable_description(
		"New Dialog - Enter Human Readable Description.")


func _create_rename_box():
	_Record_Rename_Box = _Record_Rename_Box_TSCN.instance()
	_Record_Rename_Box.connect("rename_BTN_pressed", self, "_on_Rename_Box_Rename")
	add_child(_Record_Rename_Box)


func _delete_checked_dialogs():
	for dialog in _checked_dialogs:
		_delete_dialog(dialog)
	_checked_dialogs.clear()
	emit_signal("changed_story")


func _delete_dialog(dialog):
	var did = dialog.get_did()
	erase_dialog(did)
	_remove_record(dialog)


func _delete_group(group):
	_groups.erase(group)
	_remove_group_from_story(group)


func _dialog_apply_group(did : int, group : String):
	if not _story[did]["groups"].has(group):
		_story[did]["groups"].push_back(group)


func _dialog_remove_group(did : int, group : String):
	if _story[did]["groups"].has(group):
		_story[did]["groups"].erase(group)


func _generate_did() -> int:
	if not _available_dids.empty():
		return _available_dids.pop_front()
	else:
		return _story.size() + 1


func _generate_nid(did : int) -> int:
	if not _story[did]["available_nid"].empty():
		return _story[did]["available_nid"].pop_front()
	else:
		return _story[did]["nodes"].size() + 1


func _load_data_from(new_story):
	_story = new_story.story.duplicate(true)
	_available_dids = new_story.available_dids.duplicate(true)
	_groups = new_story.groups.duplicate(true)
	_record_names = new_story.names.duplicate(true)
	


func _make_did_available(did : int):
	_available_dids.push_front(did)
	_available_dids.sort()


func _make_nid_available(did : int, nid : int):
	_story[did]["available_nid"].push_front(nid)
	_story[did]["available_nid"].sort()


func _make_records_visible():
	var children = _Dialog_Record_Root.get_children()
	for child in children:
		child.visible = true


func _populate_filter_menu():
	_Filter_Menu.get_popup().clear()
	_Filter_Menu.get_popup().add_check_item("-No Tags-")
	for group in _groups:
		_Filter_Menu.get_popup().add_check_item(group)
	for idx in range(_Filter_Menu.get_popup().get_item_count()):
		_Filter_Menu.get_popup().set_item_checked(idx, true)


func _populate_group_selector():
	_Group_Selector.clear()
	_Group_Selector.text = "Tags"
	for group in _groups:
		_Group_Selector.get_popup().add_item(group)


func _populate_searchby_menu():
	_Search_Option_BTN.clear()
	_Search_Option_BTN.get_popup().add_item("Human Readable LBL", 0)
	_Search_Option_BTN.get_popup().add_item("DID", 1)
	_Search_Option_BTN.get_popup().add_item("Record Name", 2)
	_Search_Option_BTN.select(0)

func _populate_story_menu():
	_Story_Menu.get_popup().clear()
	_Story_Menu.get_popup().add_item("New Story", 0)
	_Story_Menu.get_popup().add_item("Load Story", 1)
	_Story_Menu.get_popup().add_item("Save Story As", 2)
	_Story_Menu.get_popup().add_item("Bake Story As", 3)
	_Story_Menu.get_popup().add_item("Save CSV As", 4)
	_Story_Menu.get_popup().add_item("Load CSV", 5)
	_Story_Menu.get_popup().connect("id_pressed", self, "_on_story_menu_option_pressed")


func _remove_all_records():
	var dialog_records = _Dialog_Record_Root.get_children()
	for record in dialog_records:
		_remove_record(record)


func _remove_group_from_story(group : String):
	for did in _story:
		if _story[did]["groups"].has(group):
			_story[did]["groups"].erase(group)


func _remove_record(dialog_record):
	dialog_record.disconnect("checked", self, "_on_Dialog_checked")
	dialog_record.disconnect("unchecked", self, "_on_Dialog_unchecked")
	dialog_record.disconnect("changed_human_readable_text", self,
		"_on_Dialog_changed_human_readable_text")
	dialog_record.disconnect("rename_pressed", self, "_on_Record_Rename_pressed")
	var record_name = dialog_record.get_record_name()
	if not record_name == "NAME":
		_record_names.erase(record_name)
	
	dialog_record.free()


func _save_data_to(filename):
	var file_data
	if _Dir.file_exists(filename):
		file_data = load(filename)
		if file_data.TYPE == "EXP_Story_editor":
			file_data.names = _record_names.duplicate(true)
			file_data.story = _story.duplicate(true)
			file_data.available_dids = _available_dids.duplicate(true)
			file_data.groups = _groups.duplicate(true)
			ResourceSaver.save(filename, file_data)
	else:
		file_data = _EXP_Story.new()
		file_data.names = _record_names.duplicate(true)
		file_data.story = _story.duplicate(true)
		file_data.available_dids = _available_dids.duplicate(true)
		file_data.groups = _groups.duplicate(true)
		ResourceSaver.save(filename, file_data)


func _setup_dialogs():
	_Load_Story = EditorFileDialog.new()
	_Load_Story.mode = EditorFileDialog.MODE_OPEN_FILE
	_Load_Story.add_filter("*.tres ; Story files")
	_Load_Story.resizable = true
	_Load_Story.access = EditorFileDialog.ACCESS_RESOURCES
	_Load_Story.current_dir = "res://"
	_Load_Story.connect("file_selected", self, "_on_Load_Story_file_selected")
	add_child(_Load_Story)
	
	_Save_Story_As = EditorFileDialog.new()
	_Save_Story_As.mode = EditorFileDialog.MODE_SAVE_FILE
	_Save_Story_As.add_filter("*.tres ; Story files")
	_Save_Story_As.resizable = true
	_Save_Story_As.access = EditorFileDialog.ACCESS_RESOURCES
	_Save_Story_As.current_dir = "res://"
	_Save_Story_As.connect("file_selected", self, "_on_Save_Story_As_file_selected")
	add_child(_Save_Story_As)
	
	_Bake_Story_As = EditorFileDialog.new()
	_Bake_Story_As.mode = EditorFileDialog.MODE_SAVE_FILE
	_Bake_Story_As.add_filter("*.tres ; Baked Story files")
	_Bake_Story_As.resizable = true
	_Bake_Story_As.access = EditorFileDialog.ACCESS_RESOURCES
	_Bake_Story_As.current_dir = "res://"
	_Bake_Story_As.connect("file_selected", self, "_on_Bake_Story_As_file_selected")
	add_child(_Bake_Story_As)
	
	_Save_CSV_As = EditorFileDialog.new()
	_Save_CSV_As.mode = EditorFileDialog.MODE_SAVE_FILE
	_Save_CSV_As.add_filter("*.csv ; CSV files")
	_Save_CSV_As.resizable = true
	_Save_CSV_As.access = EditorFileDialog.ACCESS_FILESYSTEM
	_Save_CSV_As.current_dir = "res://"
	_Save_CSV_As.connect("file_selected", self, "_on_Save_CVS_As_file_selected")
	add_child(_Save_CSV_As)
	
	_Load_CSV  = EditorFileDialog.new()
	_Load_CSV .mode = EditorFileDialog.MODE_OPEN_FILE
	_Load_CSV .add_filter("*.csv ; CSV files")
	_Load_CSV .resizable = true
	_Load_CSV .access = EditorFileDialog.ACCESS_FILESYSTEM
	_Load_CSV .current_dir = "res://"
	_Load_CSV .connect("file_selected", self, "_on_Load_CSV_file_selected")
	add_child(_Load_CSV)


func _update_filter():
	var new_text = _Search_LineEdit.text
	_make_records_visible()
	
	var filter_groups : Array
	for idx in range(_Filter_Menu.get_popup().get_item_count()):
		if _Filter_Menu.get_popup().is_item_checked(idx):
			var group = _Filter_Menu.get_popup().get_item_text(idx)
			filter_groups.push_back(group)
	
	var children = _Dialog_Record_Root.get_children()
	
	var search_option = _Search_Option_BTN.selected
	
	match search_option:
		0: #Human Readable Search
			for child in children:
				var did = child.get_did()
				var human_readable_description = get_dialog_property(did, "human_readable_description")
				if human_readable_description.find(new_text) == -1 and not new_text.empty():
					child.visible = false
				else:
					child.visible = false
					if _Filter_Menu.get_popup().get_item_count() == 0:
						child.visible = true
					var dialog_groups = dialog_get_groups(did)
					if dialog_groups.empty() and filter_groups.has("-No Tags-"):
						child.visible = true
					for group in dialog_groups:
						if filter_groups.has(group):
							child.visible = true
		1: #DID Search
			for child in children:
				var did = child.get_did()
				if not new_text == str(did) and not new_text.empty():
					child.visible = false
				else:
					child.visible = false
					if _Filter_Menu.get_popup().get_item_count() == 0:
						child.visible = true
					var dialog_groups = dialog_get_groups(did)
					if dialog_groups.empty() and filter_groups.has("-No Tags-"):
						child.visible = true
					for group in dialog_groups:
						if filter_groups.has(group):
							child.visible = true
		2: #Record Name Search 
			for child in children:
				var did = child.get_did()
				var record_name = child.get_record_name()
				if record_name.find(new_text) == -1 and not new_text.empty():
					child.visible = false
				else:
					child.visible = false
					if _Filter_Menu.get_popup().get_item_count() == 0:
						child.visible = true
					var dialog_groups = dialog_get_groups(did)
					if dialog_groups.empty() and filter_groups.has("-No Tags-"):
						child.visible = true
					for group in dialog_groups:
						if filter_groups.has(group):
							child.visible = true
