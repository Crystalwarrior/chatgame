extends Node

var registry = {"PLAYER/LEVEL": 99,
				"PI": PI,
				"DATE": OS.get_datetime(),
				"SYSTEM": OS.get_name()}

# Public Methods

func lookup(name: String):
	if registry.has(name):
		return registry[name]
	else:
		return ""

func set(name: String, value):
	registry[name] = value
