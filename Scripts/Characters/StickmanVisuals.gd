class_name StickmanVisuals
extends Node2D

## StickmanVisuals: Procedural Animation & VFX Renderer
## Handles dynamic limb drawing, weapon attachment, and specialized trail effects.

@export var skeleton_path: NodePath = "../Skeleton2D"
@onready var skeleton: Skeleton2D = get_node_or_null(skeleton_path)

@export_group("Visual Style")
@export var line_color: Color = Color(0.2, 2.0, 2.5): # Neon Cyan (HDR)
	set(value):
		line_color = value
		_update_vfx_color()

@export var line_width: float = 6.0
@export var head_radius: float = 14.0
@export var head_bone_name: String = "Head" 

@export_group("Trail Settings")
@export var use_trail: bool = true
@export var trail_length: int = 14

# Weapon & Body Parts
var weapon_l: Sprite2D
var weapon_r: Sprite2D
var head_accessory: Line2D
var weapon_l_area: Area2D
var weapon_r_area: Area2D
var hitboxes: Dictionary = {}

# VFX Objects
var swing_particle: GPUParticles2D
var trail_active: bool = false
var current_trail_hand: String = "right" # "left" or "right"
var flash_timer: float = 0.0
var flash_color: Color = Color(10, 10, 10)

# Trail Buffer: Stores struct { tip: Vector2, base: Vector2 }
var trail_buffer: Array[Dictionary] = []

func _ready() -> void:
	z_index = 1 # Draw above background
	if skeleton:
		_setup_bone_sprites()
		_setup_swing_particle(weapon_r if weapon_r else self)

func _setup_bone_sprites() -> void:
	var hand_l = skeleton.find_child("HandL", true, false)
	if hand_l:
		weapon_l = Sprite2D.new(); weapon_l.name = "WeaponL"; weapon_l.z_index = 10; weapon_l.z_as_relative = true
		hand_l.add_child(weapon_l)
	
	var hand_r = skeleton.find_child("HandR", true, false)
	if hand_r:
		weapon_r = Sprite2D.new(); weapon_r.name = "WeaponR"; weapon_r.z_index = 10; weapon_r.z_as_relative = true
		hand_r.add_child(weapon_r)
		
	var head = skeleton.find_child(head_bone_name, true, false)
	if head:
		head_accessory = Line2D.new(); head_accessory.name = "HeadAccessory"; head_accessory.width = 4.0; head_accessory.z_index = 2
		head.add_child(head_accessory)

func equip_weapon(hand: String, texture: Texture2D, scale: Vector2 = Vector2(1, 1), offset: Vector2 = Vector2.ZERO, rotation: float = 0.0) -> void:
	var target = weapon_l if hand == "left" else weapon_r
	if not target: return
	
	if texture:
		target.texture = texture
		target.scale = scale
		target.rotation_degrees = rotation
		
		# [Sword Offset Calibration]
		# Image: 150x450. Center at (75, 225).
		# Target Pivot: Y=45 (Handle).
		# Offset Calculation: Pivot(45) - Center(225) = -180 Y-shift.
		if "sword" in texture.resource_path.to_lower() and offset == Vector2.ZERO:
			target.offset = Vector2(0, -180)
			target.position = Vector2.ZERO
		else:
			target.offset = Vector2.ZERO
			target.position = offset
			
		_setup_hitbox(target, texture, hand)
	else:
		target.texture = null
		_setup_bare_hitbox(target, hand)

func set_swing_trail(active: bool, hand: String = "right") -> void:
	# [FIX] Clear buffer on activation to prevent "teleporting" polygons
	if active and (not trail_active or current_trail_hand != hand):
		trail_buffer.clear()
		
	trail_active = active
	current_trail_hand = hand
	if swing_particle: swing_particle.emitting = active

func apply_hit_flash(color: Color = Color(5, 5, 5)):
	flash_timer = 0.15
	flash_color = color

func _process(delta: float) -> void:
	if flash_timer > 0: flash_timer -= delta
	queue_redraw()
	_update_trail_buffer(delta)

func _update_trail_buffer(_delta: float) -> void:
	if not use_trail:
		trail_buffer.clear()
		return
		
	var target = weapon_l if current_trail_hand == "left" else weapon_r
	if not target or not target.texture:
		trail_buffer.clear()
		return
		
	if trail_active:
		# [Trail Points Calculation]
		# Use Global Transform to ensure absolute world coordinates regardless of flipping
		# Dynamic calculation based on sprite rect
		var rect = target.get_rect()
		
		# Assuming weapon points UP (-Y) in local space
		# Top of rect is tip, Bottom of rect is base (handle area)
		var tip_local = Vector2(0, rect.position.y + 10) # +10 padding
		var base_local = Vector2(0, rect.end.y - 10)     # -10 padding
		
		var t = target.global_transform
		var p_tip = t * tip_local
		var p_base = t * base_local
		
		# [FIX] Avoid duplicate points
		if not trail_buffer.is_empty():
			var last = trail_buffer[0]
			if last["tip"].distance_squared_to(p_tip) < 9.0: # Increased threshold
				return 
		
		trail_buffer.push_front({ "tip": p_tip, "base": p_base })
	
	if trail_buffer.size() > trail_length:
		trail_buffer.resize(trail_length)
	
	if not trail_active and not trail_buffer.is_empty():
		trail_buffer.pop_back() # Fade out from tail

func _draw() -> void:
	if skeleton: draw_bones_recursive(skeleton)
	_draw_sword_trail()

func _draw_sword_trail() -> void:
	if trail_buffer.size() < 2: return
	
	# Draw Ribbons (Triangle Strip Method)
	# Safest way to avoid "Invalid Polygon" errors on self-intersection
	
	for i in range(trail_buffer.size() - 1):
		var curr = trail_buffer[i]     # Current Frame
		var prev = trail_buffer[i+1]   # Previous Frame (Older)
		
		var alpha = float(trail_buffer.size() - i) / float(trail_buffer.size())
		var col = line_color * 3.5 # [NEON] Intense HDR Color
		col.a = alpha * 0.5 # Semi-transparent
		var colors = PackedColorArray([col, col, col])
		
		# Convert Global Points to Local Space for Drawing
		var c_tip = to_local(curr["tip"])
		var c_base = to_local(curr["base"])
		var p_tip = to_local(prev["tip"])
		var p_base = to_local(prev["base"])
		
		# Tri 1: CurrTip, CurrBase, PrevTip
		var tri1 = PackedVector2Array([c_tip, c_base, p_tip])
		draw_polygon(tri1, colors)
		
		# Tri 2: PrevTip, CurrBase, PrevBase
		var tri2 = PackedVector2Array([p_tip, c_base, p_base])
		draw_polygon(tri2, colors)

# --- Drawing Helpers ---
func draw_bones_recursive(parent: Node) -> void:
	for child in parent.get_children():
		if child is Bone2D:
			var parent_pos = Vector2.ZERO
			if parent is Bone2D:
				parent_pos = to_local(parent.global_position)
				var child_pos = to_local(child.global_position)
				var c = flash_color if flash_timer > 0 else line_color
				if child.name == head_bone_name:
					# Head
					draw_arc(child_pos, head_radius, 0, TAU, 32, c, line_width, true)
				else:
					if "End" not in child.name:
						# Limbs
						draw_line(parent_pos, child_pos, c, line_width, true)
			draw_bones_recursive(child)

# --- Utility Functions (Restored & Expanded) ---

func _setup_hitbox(parent: Sprite2D, texture: Texture2D, hand: String) -> void:
	var existing = parent.get_node_or_null("WeaponArea")
	if existing: existing.queue_free()
	
	var area = Area2D.new()
	area.name = "WeaponArea"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = false
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = texture.get_size()
	col.shape = shape
	
	area.add_child(col)
	parent.add_child(area)
	
	if hand == "left":
		weapon_l_area = area
		hitboxes["weapon_l"] = area
	else:
		weapon_r_area = area
		hitboxes["weapon_r"] = area

func _setup_bare_hitbox(parent: Node2D, hand: String) -> void:
	var existing = parent.get_node_or_null("WeaponArea")
	if existing: existing.queue_free()
	
	var area = Area2D.new()
	area.name = "WeaponArea"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = false
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	col.shape = shape
	
	area.add_child(col)
	parent.add_child(area)
	
	if hand == "left":
		weapon_l_area = area
		hitboxes["weapon_l"] = area
	else:
		weapon_r_area = area
		hitboxes["weapon_r"] = area

func enable_hitbox(name: String) -> Area2D:
	if hitboxes.has(name):
		var area = hitboxes[name]
		area.set_deferred("monitoring", true)
		if area.get_parent() is Sprite2D:
			area.get_parent().modulate = Color(10.0, 0.5, 0.5) # Heat visual
		return area
	return null

func disable_all_hitboxes() -> void:
	for area in hitboxes.values():
		area.set_deferred("monitoring", false)
		if area.get_parent() is Sprite2D:
			area.get_parent().modulate = Color.WHITE

func _setup_swing_particle(parent: Node2D) -> void:
	swing_particle = GPUParticles2D.new()
	swing_particle.name = "SwingVFX"
	swing_particle.emitting = false
	swing_particle.z_index = 15
	
	var mat = ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 150.0
	mat.scale_min = 6.0
	mat.scale_max = 12.0
	
	swing_particle.process_material = mat
	swing_particle.local_coords = false # World space
	parent.add_child(swing_particle)

func _update_vfx_color() -> void:
	if swing_particle and swing_particle.process_material:
		var mat = swing_particle.process_material as ParticleProcessMaterial
		mat.color = line_color * 1.5

func equip_head_accessory(points: PackedVector2Array, color: Color) -> void:
	if head_accessory:
		head_accessory.points = points
		head_accessory.default_color = color * 1.5 # Neon

# --- Spawner Proxies (Restored) ---
func spawn_step_dust(dir: float) -> void:
	VFXManager.spawn("step_dust", global_position, line_color * 1.5, dir)

func spawn_jump_dust() -> void:
	VFXManager.spawn("jump_dust", global_position, line_color * 1.5, skeleton.scale.x)

func spawn_land_dust() -> void:
	VFXManager.spawn("land_dust", global_position, line_color * 1.5, skeleton.scale.x)

func spawn_shockwave() -> void:
	VFXManager.spawn("shockwave", global_position + Vector2(0, 20), Color(2, 2, 5))

func spawn_grand_cross() -> void:
	var pos = global_position + Vector2(0, -20)
	var gold = Color(2.5, 2.0, 0.5)
	# These specific keys must exist in the Knight's VFX Registry
	VFXManager.spawn("shockwave", pos, gold)
	VFXManager.spawn("knight_ult_beam", pos, gold, 1.0)
	VFXManager.spawn("knight_ult_beam", pos, gold, -1.0)
	VFXManager.spawn("knight_ult_beam_up", pos, gold)
	VFXManager.spawn("knight_ult_beam_down", pos, gold)
