extends Node

var registry = {"PLAYER/LEVEL": 99,
				"PI": PI,
				"DATE": OS.get_datetime(),
				"SYSTEM": OS.get_name(),
				"EVIDENCE": [
					{"name": "Knife", "icon": preload("res://icon.png"),
					"image": preload("res://icon.png"), "desc": "U"},
					{"name": "Shovel", "icon": preload("res://icon.png"),
					"image": preload("res://avatars/girl2.png"), "desc": "O"},
					{"name": "Crowbar", "icon": preload("res://icon.png"),
					"image": preload("res://avatars/girl.png"), "desc": "A"},
					{"name": "Multitool", "icon": preload("res://icon.png"),
					"image": preload("res://avatars/guy.png"), "desc": "E"},
					],
				"PRESENTED": "",
			}

# Public Methods

func lookup(name: String):
	if registry.has(name):
		return registry[name]
	else:
		return ""

func set(name: String, value):
	registry[name] = value
