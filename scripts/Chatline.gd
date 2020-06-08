extends PanelContainer

#Public vars
var text_delay = 0.02 setget set_text_delay, get_text_delay #20ms per symbol

#Private vars
#The text we're currently parsing stripped of newline chars
var _parsing_text = ""
var _timer = 0
var _wait_time = 0
var _running = false
var _paused = false

#onready vars
onready var _text = $HBoxContainer/RichTextLabel
onready var _speaker = $HBoxContainer/VBoxContainer/NameLabel
onready var _avatar = $HBoxContainer/VBoxContainer/AvatarTexture

#signals
signal blip(character)
signal finished

#setters/getters
func set_text_delay(new_value):
	text_delay = new_value

func get_text_delay():
	return text_delay

#public functions
func start():
	set_paused(false)
	_running = true

func set_paused(toggle=null):
	if toggle == null:
		toggle = not _paused
	_paused = toggle

func stop():
	_running = false
	_text.visible_characters = -1

func finished():
	stop()
	emit_signal("finished")

func is_active():
	return _running

func display_text(msg="", speaker="", avatar=null):
	if msg != "":
		_text.text = msg
	if speaker != "":
		_speaker.text = speaker
	if avatar:
		_avatar.set_texture(avatar)
	_set_text_delay(get_text_delay())
	#Strip out new lines as they're invisible to visible_characters
	_parsing_text = _text.text.replace("\n", "")
	_text.set_visible_characters(0)
	start()

#private functions
func _process(delta):
	if not _running or _paused:
		return
	if _text.visible_characters == -1 or _text.visible_characters >= _parsing_text.length():
		finished()
		return
	_timer += delta
	if _timer >= _wait_time:
		_parse_character(_parsing_text[_text.visible_characters])
		_text.visible_characters += 1
		_timer = 0

func _parse_character(character):
	#Increase the delay due to "pausing" to take your breath.
	if character in ".,!?:;-":
		_set_text_delay(get_text_delay() * 4)
	else:
		_set_text_delay(get_text_delay())
	
	emit_signal("blip", character)
#	randomize()
#	if character in " " and not space_sounds.empty():
#		_blip.set_stream(space_sounds[randi() % space_sounds.size()])
#	elif not blip_sounds.empty():
#		_blip.set_stream(blip_sounds[randi() % blip_sounds.size()])

func _set_text_delay(delay):
	_wait_time = delay
