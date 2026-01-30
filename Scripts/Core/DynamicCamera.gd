extends Camera2D

@export var player1_path: NodePath = "../Player1"
@export var player2_path: NodePath = "../Player2"
@export var min_zoom: float = 0.5 # Max zoom out (see more area)
@export var max_zoom: float = 2.0 # Max zoom in (closer view)
@export var margin: Vector2 = Vector2(400, 300) # Margin around players
@export var smooth_speed: float = 5.0
@export var y_offset: float = -100.0 # Shift camera up a bit so players aren't vertically centered (allows seeing jump height)

var player1: Node2D
var player2: Node2D

# --- Shake Settings ---
@export var shake_decay: float = 1.0 # Very slow decay so it lasts long
@export var max_shake_offset: Vector2 = Vector2(100, 100) 
@export var max_shake_roll: float = 0.2 # Increased from 0.1
var _shake_power: float = 0.0

func _ready() -> void:
	# Connect to Global Event Bus
	if VFXManager:
		VFXManager.camera_shake_requested.connect(add_trauma)
		print("DynamicCamera: Connected to VFXManager signal.")
	
	player1 = get_node_or_null(player1_path)
	player2 = get_node_or_null(player2_path)
	
	if not player1 or not player2:
		set_physics_process(false)
		push_error("DynamicCamera: Players not found! Check node paths.")

func add_trauma(amount: float) -> void:
	print("DynamicCamera: Trauma Added! Amount: %.2f, Current: %.2f" % [amount, _shake_power])
	_shake_power = min(_shake_power + amount, 1.0)

# Changed to _physics_process to sync with Player movement (CharacterBody2D)
# This prevents visual "jitter" caused by the camera updating at a different rate (fps) than the physics (tps).
func _physics_process(delta: float) -> void:
	if not player1 or not player2:
		return

	var p1_pos = player1.global_position
	var p2_pos = player2.global_position
	
	# Calculate center
	var center = (p1_pos + p2_pos) / 2.0
	var target_pos = center
	target_pos.y += y_offset
	
	# Smoothly move position (Base Position)
	# Note: We use a separate variable or just allow 'position' to track target, 
	# BUT we must subtract the previous shake offset if we want 'position' to stay stable?
	# Easier: Store base position implicitly? No, 'position' IS the property.
	# Correct Logic: 
	# 1. Do not add shake to 'position' permanently.
	# 2. But since we are in _process/physics, we render the node at 'position'.
	# 3. We cannot separate "Render Position" from "Logic Position" easily without a child node or variable.
	# FIX: Let's assume 'position' is close to target.
	# We will LERP first (cleaning up previous frame's offset implicitly because target didn't move much).
	# BUT if smooth_speed is slow, the previous frame's offset drags it.
	
	# Better: Reset to target immediately? No, we want smooth camera.
	
	# BEST FIX: 'position' should TRACK target. Shake is a CHILD node or Camera Offset?
	# Camera2D has 'offset' property! We should use that for shake!
	
	position = position.lerp(target_pos, smooth_speed * delta)
	
	# Calculate Zoom
	var screen_size = get_viewport_rect().size
	var bounds_size = (p1_pos - p2_pos).abs() + margin
	
	var zoom_x = screen_size.x / max(bounds_size.x, 100.0)
	var zoom_y = screen_size.y / max(bounds_size.y, 100.0)
	
	var target_zoom_val = min(zoom_x, zoom_y)
	target_zoom_val = clamp(target_zoom_val, min_zoom, max_zoom)
	
	var target_zoom = Vector2(target_zoom_val, target_zoom_val)
	zoom = zoom.lerp(target_zoom, smooth_speed * delta)

func _process(delta: float) -> void:
	# Use real-time delta for shake so it doesn't freeze during HitStop
	var real_delta = delta
	if Engine.time_scale > 0.0:
		real_delta = delta / Engine.time_scale
		
	# --- Apply Shake (Using built-in offset) ---
	if _shake_power > 0:
		_shake_power = max(0.0, _shake_power - shake_decay * real_delta)
		var amount = _shake_power * _shake_power # Quadratic falloff
		
		offset.x = randf_range(-1, 1) * max_shake_offset.x * amount
		offset.y = randf_range(-1, 1) * max_shake_offset.y * amount
		rotation = max_shake_roll * amount * randf_range(-1, 1)
	else:
		offset = Vector2.ZERO
		rotation = 0.0
