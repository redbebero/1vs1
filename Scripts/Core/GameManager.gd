extends Node

# Manager for global game state and diagnostics

func _ready() -> void:
	print("--- INPUT MAP DIAGNOSTIC ---")
	_check_action("p1_skill1")
	_check_action("p1_skill2")
	_find_duplicates_for_key(86) # Key V
	print("----------------------------")

func _check_action(action: String) -> void:
	if InputMap.has_action(action):
		var events = InputMap.action_get_events(action)
		print("Action '%s' has %d events:" % [action, events.size()])
		for e in events:
			if e is InputEventKey:
				print("  - Key: %s (Physical: %d)" % [OS.get_keycode_string(e.physical_keycode), e.physical_keycode])
	else:
		print("ERROR: Action '%s' does not exist!" % action)

func _find_duplicates_for_key(keycode: int) -> void:
	print("Checking for KeyCode %d (V) usage in ALL actions..." % keycode)
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and e.physical_keycode == keycode:
				print("  -> Found in Action: '%s'" % action)
