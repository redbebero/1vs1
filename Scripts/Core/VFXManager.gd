extends Node

## VFXManager (The Particle Bus)
## Manages a pool of GPUParticles2D to avoid runtime allocation/garbage collection spikes.
## This is the central hub for playing visual effects.

# Pool Configuration
const POOL_SIZE: int = 256 # Increased from 64 to handle high-particle ult overlap
var _particle_pool: Array[GPUParticles2D] = []
var _pool_index: int = 0

# --- Time Management ---
var _is_hitstop_active: bool = false

# Global Signals
signal camera_shake_requested(amount: float)

# Material Cache (Shared Resources)
var _default_gradient_tex: GradientTexture1D
var _default_curve_tex: CurveTexture

var _custom_registries: Array[Dictionary] = []

func _ready() -> void:
	_init_resources()
	_init_pool()
	process_mode = Node.PROCESS_MODE_ALWAYS # Ensure this runs even when paused (if we used pause, but we use time_scale)

func _process(_delta: float) -> void:
	# No manual hitstop counting needed if using SceneTreeTimer
	pass

func shake_camera(amount: float) -> void:
	print("VFXManager: Emitting Camera Shake Signal (Amount: %.2f)" % amount)
	emit_signal("camera_shake_requested", amount)

# Orchestrates the Hit Sequence: Freeze -> Slow + Shake -> Normal
func start_hit_impact(freeze_duration: float, slow_duration: float, shake_amount: float) -> void:
	if _is_hitstop_active:
		return 
	
	# Critical: Wait 1 frame
	await get_tree().process_frame
	
	_is_hitstop_active = true
	var original = 1.0 # Base time scale should be 1.0
	
	# Phase 1: COMPLETE FREEZE (Hard 0.0) -> Adjusted to 0.01 to allow Particle init
	print("VFXManager: [PHASE 1] HARD FREEZE - 0.01 Scale")
	Engine.time_scale = 0.01
	
	# ignore_time_scale=true is critical here to allow the timer to run
	await get_tree().create_timer(freeze_duration, true, false, true).timeout
	
	# Phase 2: SLOW MOTION & SHAKE (Starts AFTER freeze)
	print("VFXManager: [PHASE 2] SLOW MOTION (0.3) & SHAKE START")
	Engine.time_scale = 0.3
	shake_camera(shake_amount)
	
	await get_tree().create_timer(slow_duration, true, false, true).timeout
	
	# Phase 3: RESTORE
	Engine.time_scale = original
	_is_hitstop_active = false
	print("VFXManager: [PHASE 3] RESTORED")

func hit_stop(duration_real_sec: float, scale: float = 0.05) -> void:
	if _is_hitstop_active:
		print("VFXManager: HitStop Ignored (Already Active)")
		return # Simple debounce
	
	# Critical: Wait 1 frame
	await get_tree().process_frame
	
	print("VFXManager: HitStop STARTED (Scale: %.2f, Duration: %.2f)" % [scale, duration_real_sec])
	_is_hitstop_active = true
	var original = Engine.time_scale
	Engine.time_scale = scale
	
	# Use SceneTreeTimer which works reliably with ignore_time_scale=true
	await get_tree().create_timer(duration_real_sec, true, false, true).timeout
	
	Engine.time_scale = original
	_is_hitstop_active = false
	print("VFXManager: HitStop ENDED")

func _init_resources() -> void:
	# 1. Create Fade Out Gradient (Alpha 1.0 -> 0.0)
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 0.7, 1.0]
	gradient.colors = [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
	
	_default_gradient_tex = GradientTexture1D.new()
	_default_gradient_tex.gradient = gradient
	
	# 2. Create Shrink Curve (Stay large, then shrink fast at the end)
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(0.6, 0.9)) # Maintain 90% size until 60% lifetime
	curve.add_point(Vector2(1.0, 0.0))
	
	_default_curve_tex = CurveTexture.new()
	_default_curve_tex.curve = curve

func _init_pool() -> void:
	for i in range(POOL_SIZE):
		var p = GPUParticles2D.new()
		p.name = "VFX_Pool_" + str(i)
		p.emitting = false
		p.one_shot = true
		
		# Critical: Create a unique material for each pooled particle to allow individual configuration
		p.process_material = ParticleProcessMaterial.new()
		
		add_child(p)
		_particle_pool.append(p)

func register_vfx(registry_data: Dictionary) -> void:
	if not _custom_registries.has(registry_data):
		_custom_registries.append(registry_data)

## Main Entry Point: Play an effect
func spawn(effect_name: String, pos: Vector2, color: Color = Color.WHITE, facing_dir: float = 1.0) -> void:
	var data = {}
	
	# 1. Check custom registries first (character specific)
	for reg in _custom_registries:
		if reg.has(effect_name):
			data = reg[effect_name]
			break
	
	# 2. Fallback to global registry
	if data.is_empty():
		data = VFXRegistry.get_data(effect_name)
		
	if data.is_empty(): return
	
	# Procedural Effect (Expanding Ring)
	if effect_name == "impact_shockwave":
		var ring = ExpandingRing.new()
		ring.top_level = true
		ring.global_position = pos
		ring.ring_color = color
		ring.max_radius = 160.0
		ring.thickness = 15.0
		get_tree().current_scene.add_child(ring)
		return

	# Particle Effect
	var p = _get_next_particle()
	
	# Reset transform
	p.global_position = pos
	p.rotation = 0.0
	
	# Apply Visual Style
	p.modulate = color
	p.z_index = data.get("z_index", 0)
	p.amount = data.get("amount", 8)
	p.lifetime = data.get("lifetime", 1.0)
	p.explosiveness = data.get("explosiveness", 0.0)
	p.local_coords = false # Force World Space (Essential for disconnected effects)
	
	# Configure Material (Physics)
	var mat = p.process_material as ParticleProcessMaterial
	if mat:
		# Direction logic
		var base_dir = data.get("direction", Vector2.UP)
		# Flip X direction if facing left
		if facing_dir < 0:
			base_dir.x *= -1
		
		mat.direction = Vector3(base_dir.x, base_dir.y, 0)
		mat.spread = data.get("spread", 45.0)
		mat.gravity = Vector3(data.get("gravity", Vector2.ZERO).x, data.get("gravity", Vector2.ZERO).y, 0)
		
		mat.initial_velocity_min = data.get("initial_velocity_min", 0.0)
		mat.initial_velocity_max = data.get("initial_velocity_max", 0.0)
		mat.scale_min = data.get("scale_amount_min", 1.0)
		mat.scale_max = data.get("scale_amount_max", 1.0)
		mat.damping_min = data.get("damping_min", 0.0)
		mat.damping_max = data.get("damping_max", 0.0)
		
		# Apply smooth fade out and shrink
		mat.color_ramp = _default_gradient_tex
		mat.scale_curve = _default_curve_tex
		
	# Fire!
	print("VFXManager: Spawning '%s' at %s (Pool Index: %d)" % [effect_name, pos, _pool_index])
	p.one_shot = true
	p.emitting = false
	
	# Force restart to reset internal timer/color ramp (Critical for same-amount reuse)
	# restart() automatically sets emitting = true
	p.restart()

func _get_next_particle() -> GPUParticles2D:
	var p = _particle_pool[_pool_index]
	
	# Force stop if it was still running
	if p.emitting:
		p.emitting = false
	
	_pool_index = (_pool_index + 1) % POOL_SIZE
	return p

class ExpandingRing extends Node2D:
	var radius = 10.0
	var max_radius = 400.0
	var thickness = 20.0
	var ring_color = Color.WHITE
	
	func _draw():
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, ring_color, thickness, true)
	
	func _process(delta):
		radius = move_toward(radius, max_radius, 800.0 * delta)
		thickness = move_toward(thickness, 2.0, 30.0 * delta)
		modulate.a -= delta * 1.5
		queue_redraw()
		if modulate.a <= 0:
			queue_free()
