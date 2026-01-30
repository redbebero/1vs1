class_name StickmanVisuals
extends Node2D

## Skeleton2D의 Bone2D들을 실시간으로 연결하여 선(Line)으로 그려주는 스크립트입니다.
## 머리는 속이 빈 원으로, 팔다리는 관절이 있는 선으로 표현합니다.

@export var skeleton_path: NodePath = "../Skeleton2D"
@onready var skeleton: Skeleton2D = get_node_or_null(skeleton_path)

@export_group("Visual Style")
@export var line_color: Color = Color(0.2, 2.0, 2.5): # 네온 느낌의 밝은 하늘색 (HDR)
	set(value):
		line_color = value
		_update_vfx_color()

@export var line_width: float = 6.0
@export var head_radius: float = 14.0 # 머리 크기 살짝 키움
@export var head_bone_name: String = "Head" 

var weapon_l: Sprite2D
var weapon_r: Sprite2D
var weapon_l_area: Area2D
var weapon_r_area: Area2D
var hitboxes: Dictionary = {}

# --- VFX ---
var swing_particle: GPUParticles2D

func _ready() -> void:
	# Create Weapon Sprites attached to Hand Bones
	if skeleton:
		var hand_l_bone = skeleton.find_child("HandL", true, false)
		if hand_l_bone:
			weapon_l = Sprite2D.new()
			weapon_l.name = "WeaponL"
			# Left Hand = Sword (per Knight_Data.tres)
			# User: Sword Current(180) + Grip Lower (200px) -> Sprite Up
			# Rot 180: Y+ is World Up.
			weapon_l.position = Vector2(50, 200) 
			weapon_l.rotation_degrees = 180 
			weapon_l.modulate = Color.WHITE
			weapon_l.z_index = 1
			hand_l_bone.add_child(weapon_l)
		
		var hand_r_bone = skeleton.find_child("HandR", true, false)
		if hand_r_bone:
			weapon_r = Sprite2D.new()
			weapon_r.name = "WeaponR"
			# Right Hand = Shield (per Knight_Data.tres)
			# User: Shield Current(0) + Grip Lower (100px) -> Sprite Up
			# Rot 0: Y- is World Up.
			weapon_r.position = Vector2(0, -100) 
			weapon_r.rotation_degrees = 0
			weapon_r.modulate = Color.WHITE
			weapon_r.z_index = 1
			hand_r_bone.add_child(weapon_r)
			
			# Attach Swing Particle to Weapon Tip (Sword - Left for Knight usually)
			# Better: Attach to a dedicated "VFXPoint" or dynamic based on active weapon. 
			# For now, Knight uses Sword (L) for slashing.
			_setup_swing_particle(weapon_l)

func _setup_swing_particle(parent: Node2D) -> void:
	swing_particle = GPUParticles2D.new()
	swing_particle.name = "SwingVFX"
	swing_particle.emitting = false
	swing_particle.one_shot = false # Continuous for trail
	swing_particle.amount = 60 # Increased to 5x (from 12) for rich scattering
	swing_particle.lifetime = 0.4 # Visible duration
	swing_particle.explosiveness = 0.0 # Uniform emission
	
	# Tip Offset (approx 60-80px from handle) 
	swing_particle.position = Vector2(60, 0) 
	
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0) 
	mat.spread = 180.0 # Scatter
	mat.gravity = Vector3(0, 0, 0) # No gravity
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 150.0 
	mat.scale_min = 6.0 # Much bigger
	mat.scale_max = 12.0
	
	# Add dynamic curves to prevent "blobbing"
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var curve_tex = CurveTexture.new()
	curve_tex.curve = curve
	mat.scale_curve = curve_tex
	
	var grad = Gradient.new()
	grad.colors = [Color(1,1,1,1), Color(1,1,1,0)] # Fade to transparent
	var grad_tex = GradientTexture1D.new()
	grad_tex.gradient = grad
	mat.color_ramp = grad_tex
	
	# Initial color set
	mat.color = line_color * 1.5 # Glow brighter initially
	
	swing_particle.process_material = mat
	swing_particle.local_coords = false # Particles stay in world space
	parent.add_child(swing_particle)

func _update_vfx_color() -> void:
	if swing_particle and swing_particle.process_material:
		var mat = swing_particle.process_material as ParticleProcessMaterial
		# Update to new line_color with some transparency
		mat.color = line_color * 0.8
		mat.color.a = 0.6

func set_swing_trail(active: bool) -> void:
	if swing_particle:
		swing_particle.emitting = active

func spawn_shockwave() -> void:
	# Use the VFXManager pool to ensure particles render even under high load
	# The registry entry for "shockwave" handles parameters (amount=200, z_index=10, etc.)
	# We pass a High-Dynamic-Range yellow color
	VFXManager.spawn("shockwave", global_position + Vector2(0, 20), Color(1.5, 1.5, 0.5))

func create_ghost() -> void:
	# Spawns a static copy of the stickman lines that fades out
	var ghost = Node2D.new()
	ghost.top_level = true
	ghost.global_position = global_position
	ghost.scale = scale
	ghost.modulate = Color(0.5, 1.0, 1.0, 0.5) # Cyan Ghost
	
	# Copy Limbs logic (Simplified for ghost)
	# We need to snapshot the CURRENT points of limbs relative to body
	# Since _draw uses dynamic bone positions, we need to capture them.
	# Access skeleton bones.
	
	if skeleton:
		for bone in skeleton.get_children():
			if bone is Node2D:
				# Recursively draw lines?
				# Simpler: Just copy the main limbs we know.
				pass
	
	# For prototype, let's just use a simple script on the ghost that draws lines
	# matching current bone positions.
	# Actually, better: VFXManager should spawn a "GhostScene" and we pass point data.
	# But here:
	var body_points = []
	# ... (Complex to copy exact pose efficiently without bone duplication)
	# Alternative: Use "BackBufferCopy" or Screen Reading? No, too expensive.
	# Valid Approach: Just draw the main lines (Legs, Body, Arms) based on current positions.
	
	var script_code = "extends Node2D\n"
	script_code += "var lines = []\n"
	script_code += "func _draw():\n"
	script_code += "  for l in lines: draw_line(l[0], l[1], Color.WHITE, 2.0)\n"
	script_code += "func _process(delta): modulate.a -= delta * 2.0; if modulate.a <= 0: queue_free()\n"
	
	var gd_script = GDScript.new()
	gd_script.source_code = script_code
	gd_script.reload()
	
	ghost.set_script(gd_script)
	
	# Collect Lines
	var lines = []
	# Head (Circle - handled differently, maybe ignore or draw circle)
	# Limbs
	var bonds = [
		["Hip", "Head"], ["Hip", "LegL"], ["Hip", "LegR"],
		["Head", "ArmL"], ["Head", "ArmR"]
	]
	
	for b in bonds:
		var node1 = skeleton.find_child(b[0], true, false)
		var node2 = skeleton.find_child(b[1], true, false)
		if node1 and node2:
			# Get LOCAL positions relative to Fighter Root (which is global_position of ghost)
			lines.append([node1.position, node2.position])
	
	ghost.set("lines", lines)
	get_tree().current_scene.add_child(ghost)

func equip_weapon(hand: String, texture: Texture2D, scale: Vector2 = Vector2(1, 1), offset: Vector2 = Vector2.ZERO) -> void:
	if hand == "left" and weapon_l:
		weapon_l.texture = texture
		# Apply Data-Driven Offset
		weapon_l.position = offset 
		# Apply independent scale if provided/available (Logic passed from controller)
		weapon_l.scale = scale
		_setup_hitbox(weapon_l, texture, "left")
	elif hand == "right" and weapon_r:
		weapon_r.texture = texture
		weapon_r.scale = scale
		weapon_r.position = offset
		_setup_hitbox(weapon_r, texture, "right")

func _setup_hitbox(parent: Sprite2D, texture: Texture2D, hand: String) -> void:
	# Clear existing area if any (simple approach)
	var existing = parent.get_node_or_null("WeaponArea")
	if existing: existing.queue_free()
	
	var area = Area2D.new()
	area.name = "WeaponArea"
	area.collision_layer = 0
	area.collision_mask = 1 # Hits CharacterBody2D
	area.monitoring = false # Disabled by default
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = texture.get_size()
	col.shape = shape
	
	area.add_child(col)
	parent.add_child(area)
	
	# Removed debug ColorRect logic as requested

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
		
		# Change Weapon Color (Flash Red/Glow)
		if area.get_parent() is Sprite2D:
			area.get_parent().modulate = Color(10.0, 0.5, 0.5) # Intense Red/White HDR
			
		return area
	return null

func disable_all_hitboxes() -> void:
	for area in hitboxes.values():
		area.set_deferred("monitoring", false)
		# Reset Weapon Color
		if area.get_parent() is Sprite2D:
			area.get_parent().modulate = Color.WHITE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not skeleton:
		return
	draw_bones_recursive(skeleton)

func draw_bones_recursive(parent: Node) -> void:
	for child in parent.get_children():
		if child is Bone2D:
			var parent_pos = Vector2.ZERO
			
			if parent is Bone2D:
				parent_pos = to_local(parent.global_position)
				var child_pos = to_local(child.global_position)
				
				if child.name == head_bone_name:
					draw_arc(child_pos, head_radius, 0, TAU, 32, line_color, line_width, true)
				else:
					if not "End" in child.name:
						draw_line(parent_pos, child_pos, line_color, line_width, true)
			
			draw_bones_recursive(child)

# --- VFX Spawning (Delegated to VFXManager) ---

func spawn_step_dust(direction_x: float) -> void:
	VFXManager.spawn("step_dust", global_position + Vector2(0, 0), line_color, direction_x)

func spawn_jump_dust() -> void:
	VFXManager.spawn("jump_dust", global_position + Vector2(0, 0), line_color, skeleton.scale.x)

func spawn_land_dust() -> void:
	VFXManager.spawn("land_dust", global_position + Vector2(0, 0), line_color, skeleton.scale.x)
