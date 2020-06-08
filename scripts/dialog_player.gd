extends Node

onready var _chatline = preload("res://scenes/Chatline.tscn")
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
	self._Story_Reader = Story_Reader_Class.new()
	
	var story = load("res://stories/Example_Story_Baked.tres")
	self._Story_Reader.read(story)

	self.play_dialog("Plains/Battle/Slime")

# Callback Methods


func _on_NextButton_pressed():
	if not self._playing_dialog:
		return
	if not _waiting:
		self._get_next_node()
		if self._playing_dialog:
			self._play_node()
	elif _current_instance:
		_current_instance.finished()


func _on_Chatline_finished():
	_waiting = false


# Public Methods

func play_dialog(record_name : String):
	self._playing_dialog = true
	self._did = self._Story_Reader.get_did_via_record_name(record_name)
	self._nid = self._Story_Reader.get_nid_via_exact_text(self._did, "<start>")
	self._get_next_node()
	self._play_node()

# Private Methods

func _get_next_node():
	self._nid = self._Story_Reader.get_nid_from_slot(self._did, self._nid, 0)
	var final_nid = self._Story_Reader.get_nid_via_exact_text(self._did, "<end>")
	
	if self._nid == final_nid:
		self._playing_dialog = false


func _get_tagged_text(tag : String, text : String):
	var start_tag = "<" + tag + ">"
	var end_tag = "</" + tag + ">"
	var start_index = text.find(start_tag) + start_tag.length()
	var end_index = text.find(end_tag)
	var substr_length = end_index - start_index
	return text.substr(start_index, substr_length)


func _play_node():
	var raw_text = self._Story_Reader.get_text(self._did, self._nid)
	var speaker_name = self._get_tagged_text("speaker", raw_text)
	var dialog = self._get_tagged_text("dialog", raw_text)
	var avatar = load(self._get_tagged_text("avatar", raw_text))
	
	_waiting = true

	_current_instance = _chatline.instance()
	_current_instance.connect("finished", self, "_on_Chatline_finished")
	_box.add_child(_current_instance)
	yield(get_tree(), "idle_frame")
	_scrollcontainer.scroll_vertical = _scrollbar.max_value
	_current_instance.display_text(dialog, speaker_name, avatar)
