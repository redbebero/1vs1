extends Node

# Manager for global game state and diagnostics

func _ready() -> void:
	# 씬이 변경될 때마다 setup_players를 호출하도록 신호 연결
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	# 플레이어가 씬에 추가되면 잠시 후 세팅 실행
	if node.is_in_group("Player"):
		call_deferred("setup_players")

func setup_players() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty(): return
	
	for p in players:
		if p is CharacterBody2D:
			# 이미 데이터가 있으면 스킵
			if p.character_data != null: continue
			
			var data: CharacterData = null
			if p.player_id == 1: data = Global.p1_data
			else: data = Global.p2_data
			
			if data:
				p.character_data = data
				if p.has_method("_apply_character_data"):
					p._apply_character_data()
					p.current_hp = p.character_data.max_hp
					p.max_hp = p.character_data.max_hp
				print("GameManager: Setup Player %d with %s" % [p.player_id, data.resource_path])

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
