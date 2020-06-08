extends PanelContainer


onready var pic = $HBoxContainer/ColorRect
onready var text = $HBoxContainer/RichTextLabel

var wordlist = [
	'Alfa', 'Bravo',
	'Charlie', 'Delta',
	'Echo', 'Foxtrot',
	'Golf', 'Hotel',
	'India', 'Juliett',
	'Kilo', 'Lima',
	'Mike', 'November',
	'Oscar', 'Papa',
	'Quebec', 'Romeo',
	'Sierra', 'Tango',
	'Uniform', 'Victor',
	'Whiskey', 'X-ray',
	'Yankee', 'Zulu'
]

func _ready():
	randomize()
	pic.color = Color(randf(), randf(), randf())
	for i in range(randi() % 30 + 1):
		if i > 0:
			text.text += ' '
		text.text += wordlist[randi() % wordlist.size()]
