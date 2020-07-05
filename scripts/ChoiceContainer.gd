extends PanelContainer


signal clicked(slot)

onready var _ChoiceTemplate = $ChoiceTemplate
onready var _Container = $VBoxContainer


func _ready():
	_add_option("Option 1")
	_add_option("Option 2")
	_add_option("Option 3")

func _add_option(text : String):
	var option = _ChoiceTemplate.duplicate()
	_Container.add_child(option)
	option.set_text(text)
	option.set_visible(true)
	option.connect("pressed", self, "_button_pressed", [option.get_index()])


func _button_pressed(slot : int):
	var option = _Container.get_child(slot)
#	option.pressed = true
	for child in _Container.get_children():
#		child.disabled = true
		child.release_focus()
		child.mouse_filter = MOUSE_FILTER_IGNORE
	emit_signal("clicked", slot)
