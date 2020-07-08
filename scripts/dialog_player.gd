extends Node

onready var _chatline = preload("res://scenes/Chatline.tscn")
onready var _choice_container = preload("res://scenes/ChoiceContainer.tscn")
onready var _box = $ScrollContainer/VBoxContainer
onready var _scrollcontainer = $ScrollContainer
onready var _scrollbar = $ScrollContainer.get_v_scrollbar()

var _did = 0
var _nid = 0
var _Story_Reader
var _playing_dialog = false
var _current_instance
var _waiting = true

# Virtual Methods

func _ready():
	var Story_Reader_Class = load("res://addons/EXP-System-Dialog/Reference_StoryReader/EXP_StoryReader.gd")
	_Story_Reader = Story_Reader_Class.new()
	
	var story = load("res://stories/main_story_baked.tres")
	_Story_Reader.read(story)

	play_dialog("prologue/intro")

# Callback Methods


func _on_NextButton_pressed():
	if not _playing_dialog:
		return
	if not _waiting:
		_get_next_node()
		if _playing_dialog:
			_play_node()
	elif _current_instance:
		_current_instance.finished()


func _on_Chatline_finished():
	_waiting = false


# Public Methods

func play_dialog(record_name : String):
	_playing_dialog = true
	_did = _Story_Reader.get_did_via_record_name(record_name)
	_nid = 1#_Story_Reader.get_nid_via_exact_text(_did, "<start>")
	_play_node()

# Private Methods

func _get_next_node(slot : int = 0):
	if (_Story_Reader.has_slot(_did, _nid, slot)):
		_nid = _Story_Reader.get_nid_from_slot(_did, _nid, slot)
	else:
		_playing_dialog = false


func _get_tagged_text(tag : String, text : String):
	var start_tag = "<" + tag + ">"
	var end_tag = "</" + tag + ">"
	var start_index = text.find(start_tag) + start_tag.length()
	var end_index = text.find(end_tag)
	var substr_length = end_index - start_index
	return text.substr(start_index, substr_length)


func _inject_variables(text : String, start_check : String = "{", end_check : String = "}") -> String:
	while text.find(start_check) != -1:
		var start_index = text.find(start_check)
		var end_index = text.find(end_check)
		if end_index == -1:
			break
		end_index += end_check.length()
		var substr_length = end_index - start_index
		var variable_value = Registry.lookup(text.substr(start_index + start_check.length(), substr_length - (start_check.length() + end_check.length())))
		text.erase(start_index, substr_length)
		text = text.insert(start_index, str(variable_value))

	return text

#probably should use regex for this, would be easier
func _parse_methods(text: String):
	while text.find("\\") != -1:
		var start_index = text.find("\\")
		var end_index = text.substr(start_index).find("]")
		if end_index == -1:
			end_index = text.substr(start_index).find("\n")
			if end_index == -1:
				#if this is end of string, it will return -1 anyway
				end_index = text.substr(start_index).find(" ")

		var extract = text.substr(start_index+1, end_index-1)
		var method = _parse_call(extract)
		assert(has_method("_diag_%s" % method[0]))
		callv("_diag_%s" % method[0], method[1])

		if end_index == -1:
			end_index = text.length()
		else:
			end_index += 1
		text.erase(start_index, end_index)

	return text

#Returns a result Array with index 0 being the method name, and index 1 being the arguments that were passed.
func _parse_call(text: String) -> Array:
	var result = ["", []]
	var split = text.split("[")
	result[0] = split[0]
	if len(split) > 1:
		result[1] = split[1].replace("]", "").split(",")
		for i in range(result[1].size()):
			var string = result[1][i]
			string = string.strip_edges()
			result[1][i] = string
	return result

func _play_node():
	var raw_text = _Story_Reader.get_text(_did, _nid)
	raw_text = _inject_variables(raw_text)
	raw_text = _parse_methods(raw_text)
	var dialog = raw_text
	var speaker = ""
	var colon = raw_text.find(":")
	if colon != -1:
		speaker = raw_text.substr(0, colon).strip_edges()
		dialog = raw_text.substr(colon+1).strip_edges()

	_waiting = true

	_current_instance = _chatline.instance()
	_current_instance.connect("finished", self, "_on_Chatline_finished")
	_box.add_child(_current_instance)
	yield(get_tree(), "idle_frame")
	_scrollcontainer.scroll_vertical = _scrollbar.max_value
	_current_instance.display_text(dialog, speaker, load("res://avatars/guy.png"))

func _diag_test():
	print("Test success!")

func _diag_question(question: String):
	print("We have to ask question '%s'" % question)

func _diag_q(question: String):
	_diag_question(question)

func _diag_input(type: String, entry):
	print("Input type '%s' requested on entry '%s'" % [type, entry])
