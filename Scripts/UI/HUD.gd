extends CanvasLayer

var p1_bar: ProgressBar
var p2_bar: ProgressBar
var p1_damage_bar: ProgressBar
var p2_damage_bar: ProgressBar

func _ready() -> void:
	# UI Setup
	# UI Setup
	p1_bar = get_node_or_null("P1_Bar")
	if not p1_bar:
		p1_bar = _create_bar(1)
		p1_damage_bar = _create_damage_bar(1, p1_bar)
		add_child(p1_damage_bar) # Behind main bar
		add_child(p1_bar)
	
	p2_bar = get_node_or_null("P2_Bar")
		
	if not p2_bar:
		p2_bar = _create_bar(2)
		p2_damage_bar = _create_damage_bar(2, p2_bar)
		add_child(p2_damage_bar)
		add_child(p2_bar)
		
	# Initial Update (Force full)
	update_health(1, 100, 100)
	update_health(2, 100, 100)

func _process(delta: float) -> void:
	if p1_damage_bar:
		p1_damage_bar.value = lerpf(p1_damage_bar.value, p1_bar.value, 5.0 * delta)
	if p2_damage_bar:
		p2_damage_bar.value = lerpf(p2_damage_bar.value, p2_bar.value, 5.0 * delta)

func _create_bar(id: int) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.name = "P%d_Bar" % id
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(400, 30)
	
	# Background (Transparent for Top Layer)
	var bg = StyleBoxEmpty.new()
	bar.add_theme_stylebox_override("background", bg)
	
	# Foreground (Green) - Real HP
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.8, 0.2) # Green
	bar.add_theme_stylebox_override("fill", fill)
	
	if id == 1:
		bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
		bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		# bar.position = Vector2(50, 600) # Removed manual position
		# Adjust anchors to stick to bottom left with padding
		bar.anchor_top = 0.9
		bar.anchor_bottom = 0.95
		bar.anchor_left = 0.05
		bar.anchor_right = 0.35
		bar.offset_left = 0
		bar.offset_top = 0
		bar.offset_right = 0
		bar.offset_bottom = 0
	else:
		bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		# bar.position = Vector2(1152 - 450, 600) # Removed manual position
		# Adjust anchors
		bar.anchor_top = 0.9
		bar.anchor_bottom = 0.95
		bar.anchor_left = 0.65
		bar.anchor_right = 0.95
		bar.offset_left = 0
		bar.offset_top = 0
		bar.offset_right = 0
		bar.offset_bottom = 0
	
	return bar
	
	return bar

func _create_damage_bar(id: int, parent_bar: ProgressBar) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.name = "P%d_DamageBar" % id
	bar.show_percentage = false
	bar.custom_minimum_size = parent_bar.custom_minimum_size
	bar.fill_mode = parent_bar.fill_mode
	
	# Position needs to match parent exactly.
	# Since we add to CanvasLayer separately, we must ensure layout matches.
	# Better: Add DamageBar BEHIND the Real Bar in the tree order.
	# But visuals: Yellow needs to be VISIBLE behind Green.
	# Standard ProgressBar draws BG then Fill.
	# If we have Green Bar on top, its BG will cover the Yellow Bar underneath.
	# So:
	# 1. Red Bar (Background container, 100% width?) OR
	# 2. Damage Bar (Yellow) has Red Background. Real Bar (Green) has Transparent Background.
	
	# Strategy:
	# Layer 1 (Bottom): Damage Bar (Value=Lagged HP). Background=Red. Fill=Yellow.
	# Layer 2 (Top): Real Bar (Value=Real HP). Background=Transparent. Fill=Green.
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.8, 0.1, 0.1) # Red Background
	bar.add_theme_stylebox_override("background", bg)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.8, 0.2) # Yellow Fill
	bar.add_theme_stylebox_override("fill", fill)
	
	# Anchors copy
	bar.anchor_top = parent_bar.anchor_top
	bar.anchor_bottom = parent_bar.anchor_bottom
	bar.anchor_left = parent_bar.anchor_left
	bar.anchor_right = parent_bar.anchor_right
	bar.offset_left = parent_bar.offset_left
	bar.offset_top = parent_bar.offset_top
	bar.offset_right = parent_bar.offset_right
	bar.offset_bottom = parent_bar.offset_bottom
	
	return bar

# ... Update logic needs to ensure Green bar has transparent BG


func update_health(player_id: int, current: float, max_val: float) -> void:
	var target_bar = p1_bar if player_id == 1 else p2_bar
	var damage_bar = p1_damage_bar if player_id == 1 else p2_damage_bar
	
	if target_bar:
		target_bar.max_value = max_val
		target_bar.value = current
		
		# If healing, update damage bar instantly
		if damage_bar and damage_bar.value < current:
			damage_bar.value = current
		# If damage, let _process lerp it down
		if damage_bar:
			damage_bar.max_value = max_val
