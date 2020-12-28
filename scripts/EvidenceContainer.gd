extends PanelContainer

signal present_evidence(slot)

onready var itemlist = $VBoxContainer/HBoxContainer/ItemList
onready var evi_icon = $VBoxContainer/HBoxContainer/Infobox/Image
onready var evi_desc = $VBoxContainer/HBoxContainer/Infobox/Description
onready var present_button = $VBoxContainer/HBoxContainer/Infobox/Present
onready var cancel_button = $VBoxContainer/HBoxContainer/Infobox/Cancel

var evi_list = []

func _ready():
	_initialize_evidence()

func _initialize_evidence():
	evi_list = Registry.lookup("EVIDENCE")
	itemlist.clear()
	for evi in evi_list:
		itemlist.add_item(evi["name"], evi["icon"])

func _on_Cancel_pressed():
	self.set_visible(false)

func _on_ItemList_item_activated(index):
	print("clicc")

func _on_ItemList_item_selected(index):
	present_button.set_disabled(false)
	var desc = evi_list[index]["desc"]
	var image = evi_list[index]["image"]
	evi_icon.set_texture(image)
	evi_desc.set_text(desc)


func _on_Present_pressed():
	var slot = itemlist.get_selected_items()[0]
	print("Presenting evidence %s" % slot)
	emit_signal("present_evidence", slot)
