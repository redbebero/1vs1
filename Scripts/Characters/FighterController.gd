extends CharacterBody2D

## 1대1 격투 게임 캐릭터 컨트롤러
## 물리 이동과 입력 처리를 담당하며, 애니메이션은 ProceduralAnimator에게 위임합니다.

@export_group("Player Settings")
@export var player_id: int = 1 : 
	set(v):
		player_id = clamp(v, 1, 2)
		input_prefix = "p%d_" % player_id

@export var class_id: int = 1 # 1 = Knight

@export_group("Data")
@export var character_data: CharacterData
@export var passives: Array[Passive] = [] # Runtime Passives list

# 전투 스탯 (현재 HP 등)
var current_hp: float = 100.0
var max_hp: float = 100.0

var speed: float = 350.0
var acceleration: float = 2500.0
var friction: float = 1800.0
var jump_force: float = -700.0
var air_resistance: float = 800.0
var gravity_scale: float = 2.5

# --- 컴포넌트 참조 ---
@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var animator: ProceduralAnimator = $ProceduralAnimator
@onready var visuals: StickmanVisuals = $StickmanVisuals

var input_prefix: String = "p1_"
var start_position: Vector2

# --- Skill System ---
enum SkillPhase { STARTUP, ACTIVE, RECOVERY }
var current_skill: Skill = null
var skill_phase: SkillPhase = SkillPhase.STARTUP
var skill_timer: float = 0.0
var slot_cooldowns: Dictionary = {0: 0.0, 1: 0.0, 2: 0.0} # A, B, Ult (Shared Cooldowns)
var current_hitbox: Area2D = null
var run_trail_timer: float = 0.0

signal health_changed(id: int, current: float, max: float)

func _ready() -> void:
	start_position = global_position
	add_to_group("Player") # Group for easier finding
	
	if skeleton:
		skeleton.scale.x = 1.0 if player_id == 1 else -1.0
		
	# P1/P2 Color Setup
	if visuals:
		if player_id == 1:
			visuals.line_color = Color(0.2, 0.5, 1.0) # Player 1 Blue
		else:
			visuals.line_color = Color(1.0, 0.2, 0.2) # Player 2 Red

	# Load Class Data
	if class_id == 1:
		character_data = load("res://Scripts/Resources/Characters/Knight/Knight_Data.tres")

	if character_data:
		_apply_character_data()
		current_hp = character_data.max_hp
		max_hp = character_data.max_hp

	# Connect to HUD
	# Waiting for one frame might be safer if HUD initializes later, but usually _ready is fine
	call_deferred("_connect_hud")

func _connect_hud() -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("update_health"):
		if not health_changed.is_connected(hud.update_health):
			health_changed.connect(hud.update_health)
			emit_signal("health_changed", player_id, current_hp, max_hp)

func _init_passives() -> void:
	passives.clear()
	if character_data and character_data.passives:
		for passive_script in character_data.passives:
			if passive_script is Script:
				var p_instance = passive_script.new()
				if p_instance is Passive:
					passives.append(p_instance)
					print("Loaded Passive: ", p_instance.passive_name)
	
	for p in passives:
		p.on_ready(self)

func _process(delta: float) -> void:
	for p in passives:
		p.on_process(self, delta)


func _apply_character_data() -> void:
	_init_passives()
	
	speed = _calculate_stat("speed", character_data.speed)
	acceleration = character_data.acceleration
	friction = character_data.friction
	jump_force = character_data.jump_force
	air_resistance = character_data.air_resistance
	gravity_scale = character_data.gravity_scale
	
	if visuals:
		# Weapon textures only, don't overwrite P1/P2 line color
		visuals.head_radius = character_data.head_radius
		visuals.line_width = character_data.line_width
		
		if character_data.weapon_l_texture:
			# Use weapon_scale_l if defined (non-zero?), else fallback to weapon_scale? 
			# Actually defaults are set in CharacterData.
			visuals.equip_weapon("left", character_data.weapon_l_texture, character_data.weapon_scale_l, character_data.weapon_offset_l)
		if character_data.weapon_r_texture:
			visuals.equip_weapon("right", character_data.weapon_r_texture, character_data.weapon_scale_r, character_data.weapon_offset_r)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	_update_cooldowns(delta)
	
	if current_skill:
		_process_skill_frame(delta)
	else:
		handle_movement(delta)
		handle_jump()
		handle_skills()
	
	# Continuous Run Trail (Juice)
	if is_on_floor() and abs(velocity.x) > 100:
		run_trail_timer -= delta
		if run_trail_timer <= 0:
			run_trail_timer = 0.05 # Emit every 0.05s
			if visuals:
				visuals.spawn_step_dust(sign(velocity.x))
	
	move_and_slide()
	
	# 애니메이션 상태 업데이트 (위임)
	_update_animation_state()

func _process_skill_frame(delta: float) -> void:
	skill_timer += delta
	
	# Expanding Hitbox Logic (Generic for any character)
	if skill_phase == SkillPhase.ACTIVE and current_skill and current_skill.hitbox_type == Skill.HitboxType.EXPANDING and current_hitbox:
		var col = current_hitbox.get_node_or_null("CollisionShape2D")
		if col and col.shape:
			var duration = max(0.01, current_skill.expansion_duration)
			var progress = clamp(skill_timer / duration, 0.0, 1.0)
			
			if col.shape is RectangleShape2D:
				col.shape.size = current_skill.hitbox_size * progress
			elif col.shape is CircleShape2D:
				# Use hitbox_size.x as radius for Circle types
				col.shape.radius = current_skill.hitbox_size.x * progress
	
	match skill_phase:
		SkillPhase.STARTUP:
			if skill_timer >= current_skill.startup_time:
				_enter_active_phase()
		
		SkillPhase.ACTIVE:
			# 하드코딩된 Active 시간 (0.2s)
			if skill_timer >= 0.2: 
				_enter_recovery_phase()
				
		SkillPhase.RECOVERY:
			# Combo Window: Allow canceling into new skills if "can_cancel" is true
			if current_skill.can_cancel:
				handle_skills() # Check for new inputs
			
			# 하드코딩된 Recovery 시간 (0.2s)
			if skill_timer >= 0.2:
				_end_skill()

func _enter_active_phase() -> void:
	skill_phase = SkillPhase.ACTIVE
	skill_timer = 0.0
	
	# Hitbox Logic
	if current_skill.hitbox_name != "":
		# Named Hitbox (Weapon/Bone)
		if visuals:
			var area = visuals.enable_hitbox(current_skill.hitbox_name)
			if area:
				_setup_persistent_hitbox(area)
				current_hitbox = area
	else:
		# Fixed Hitbox
		if current_skill.hitbox_size != Vector2.ZERO:
			_spawn_hitbox()
		
	if visuals:
		# Enable Trail (Blue Effect tick by tick)
		visuals.set_swing_trail(true)
		
		# Trigger Shockwave if tagged
		if current_skill.tags.has("shockwave"):
			print("P%d Controller: Triggering Shockwave!" % player_id)
			visuals.spawn_shockwave()
			# Camera Shake for Impact
			VFXManager.shake_camera(0.6)
		
	# Apply initial forces (Dash, Jump)
	if current_skill.tags.has("dash"):
		velocity.x = skeleton.scale.x * 800 # Dash impulse
	if current_skill.tags.has("anti-air"):
		velocity.y = -600 

func _setup_persistent_hitbox(area: Area2D) -> void:
	area.set_meta("damage", current_skill.damage)
	area.set_meta("knockback", current_skill.knockback)
	area.set_meta("stun", current_skill.stun_duration)
	
	if not area.body_entered.is_connected(_on_hitbox_body_entered):
		area.body_entered.connect(_on_hitbox_body_entered.bind(area))

func _enter_recovery_phase() -> void:
	skill_phase = SkillPhase.RECOVERY
	skill_timer = 0.0
	
	# Disable Trail
	if visuals:
		visuals.set_swing_trail(false)
		
	_disable_current_hitbox()

func _end_skill() -> void:
	current_skill = null
	
	# Ensure Trail is off
	if visuals:
		visuals.set_swing_trail(false)
		
	_disable_current_hitbox()

func _disable_current_hitbox() -> void:
	if current_hitbox:
		if current_hitbox.name == "WeaponArea": # Persistent
			if visuals: visuals.disable_all_hitboxes()
		else: # Fixed (Spawned)
			current_hitbox.queue_free()
		current_hitbox = null

func _spawn_hitbox() -> void:
	var area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1 # Hits CharacterBody2D (Layer 1 usually)
	
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D" # Explicit name for lookup
	
	var shape
	if current_skill.shape_type == Skill.ShapeType.CIRCLE:
		shape = CircleShape2D.new()
		if current_skill.hitbox_type == Skill.HitboxType.EXPANDING:
			shape.radius = 0.0
		else:
			shape.radius = current_skill.hitbox_size.x
	else:
		shape = RectangleShape2D.new()
		if current_skill.hitbox_type == Skill.HitboxType.EXPANDING:
			shape.size = Vector2.ZERO
		else:
			shape.size = current_skill.hitbox_size
			
	collision.shape = shape
	
	area.add_child(collision)
	add_child(area)
	
	# Position Hitbox
	var facing = skeleton.scale.x
	area.position = Vector2(current_skill.hitbox_offset.x * facing, current_skill.hitbox_offset.y)
	
	# Connect Signal
	area.body_entered.connect(_on_hitbox_body_entered.bind(area))
	
	# Metadata
	area.set_meta("damage", current_skill.damage)
	area.set_meta("knockback", current_skill.knockback)
	area.set_meta("stun", current_skill.stun_duration)
	
	current_hitbox = area
	
	# Debug ColorRect removed as requested

func _on_hitbox_body_entered(body: Node, hitbox: Area2D) -> void:
	if body is CharacterBody2D and body != self and body.has_method("take_damage"):
		print("P%d Hit Registered on %s!" % [player_id, body.name])
		var dmg = hitbox.get_meta("damage")
		var kb_force = hitbox.get_meta("knockback")
		var stun = hitbox.get_meta("stun")
		
		# Knockback direction depends on attacker facing
		var facing = skeleton.scale.x
		var final_kb = kb_force * Vector2(facing, 1.0)
		
		# Hitstop handled by Defender (global time scale)
		
		body.take_damage(dmg, global_position, final_kb, stun)
		
		# Spawn Hit Effect
		var hit_colors = [Color.YELLOW, Color.ORANGE, Color(1, 1, 0.8), Color.GOLD]
		var hit_col = hit_colors.pick_random()
		VFXManager.spawn("hit_impact", body.global_position + Vector2(0, -50), hit_col, facing)
		
		# Disable hitbox after hit to prevent multi-hit per frame (simple logic)
		hitbox.set_deferred("monitoring", false)

func _start_skill(skill: Skill, slot_index: int) -> void:
	current_skill = skill
	skill_phase = SkillPhase.STARTUP
	skill_timer = 0.0
	
	if current_skill.animation:
		play_motion(current_skill.animation)
	
	if slot_index != -1 and skill.cooldown > 0:
		slot_cooldowns[slot_index] = skill.cooldown
		
	velocity.x = 0

func _update_cooldowns(delta: float) -> void:
	for slot in slot_cooldowns.keys():
		if slot_cooldowns[slot] > 0:
			slot_cooldowns[slot] -= delta

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale * delta

func handle_movement(delta: float) -> void:
	var move_dir := Input.get_axis(input_prefix + "left", input_prefix + "right")
	
	if move_dir != 0:
		velocity.x = move_toward(velocity.x, move_dir * speed, acceleration * delta)
		if skeleton:
			skeleton.scale.x = sign(move_dir)
	else:
		var current_friction = friction if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

func handle_jump() -> void:
	if is_on_floor() and Input.is_action_just_pressed(input_prefix + "up"):
		velocity.y = jump_force
	if Input.is_action_just_released(input_prefix + "up") and velocity.y < 0:
		velocity.y *= 0.4

func handle_skills() -> void:
	if not character_data:
		return
		
	var dir_input = Vector2(
		Input.get_axis(input_prefix + "left", input_prefix + "right"),
		Input.get_axis(input_prefix + "up", input_prefix + "down")
	)
	
	var dir_key = "neutral"
	if abs(dir_input.x) > 0.5:
		dir_key = "side"
	elif dir_input.y < -0.5:
		dir_key = "up"
	elif dir_input.y > 0.5:
		dir_key = "down"
	
	var selected_skill: Skill = null
	var slot_index: int = -1
	
	if Input.is_action_just_pressed(input_prefix + "skill1"):
		selected_skill = character_data.skill_a.get(dir_key)
		slot_index = 0
	elif Input.is_action_just_pressed(input_prefix + "skill2"):
		selected_skill = character_data.skill_b.get(dir_key)
		slot_index = 1
	elif Input.is_action_just_pressed(input_prefix + "skill3"):
		selected_skill = character_data.ult
		slot_index = 2
		
	if selected_skill and slot_index != -1 and slot_cooldowns[slot_index] <= 0:
		# If we are already in a skill (Comboing), end it first properly or just overwrite
		if current_skill:
			_end_skill() # Force end previous skill to start new one immediately
		_start_skill(selected_skill, slot_index)

# --- Interface for Skills ---
func play_motion(data: MotionData) -> void:
	if animator:
		animator.play_motion(data)

func is_playing_motion() -> bool:
	if animator:
		return animator._current_motion != null
	return false

func _update_animation_state() -> void:
	if not animator: return
	if current_skill or is_playing_motion(): return
	
	var state_name = "Idle"
	if is_on_floor():
		state_name = "Run" if abs(velocity.x) > 20 else "Idle"
	else:
		state_name = "Jump" if velocity.y < 0 else "Fall"
	
	animator.update_state(state_name, velocity, is_on_floor())

# --- Combat & Juice ---
func take_damage(amount: float, source_pos: Vector2, knockback: Vector2, stun: float) -> void:
	var final_damage = amount
	
	if character_data:
		final_damage *= (1.0 - character_data.damage_reduction)
		# Knight Passive Logic MOVED to SilverGrace.gd (Data Driven!)
	
	# Passive Hook: on_take_damage
	for p in passives:
		final_damage = p.on_take_damage(self, null, final_damage) # Source is complicated to get perfectly here without passing object
	
	current_hp -= final_damage
	print("P%d took %.1f damage! HP: %.1f" % [player_id, final_damage, current_hp])
	
	# Passive Hook: on_hit (after damage)
	for p in passives:
		p.on_hit(self, null)
	
	emit_signal("health_changed", player_id, current_hp, max_hp)
	
	velocity = knockback
	
	# Juice: Hit Sequence (Freeze -> Slow + Shake)
	# 0.2s 정지 (Hard Freeze) -> 0.25s 슬로우(0.3) & 쉐이크(0.35)
	VFXManager.start_hit_impact(0.2, 0.25, 0.35)
		
	# Juice: White Flash
	if visuals:
		var tween = create_tween()
		visuals.modulate = Color(3.0, 3.0, 3.0) # HDR White
		tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)
	
	# Check Death
	if current_hp <= 0:
		die()

func die() -> void:
	print("P%d Died!" % player_id)
	# Simple Respawn Logic
	global_position = start_position
	current_hp = max_hp
	emit_signal("health_changed", player_id, current_hp, max_hp)
	velocity = Vector2.ZERO
	# Reset cooldowns? Maybe.
	for k in slot_cooldowns.keys():
		slot_cooldowns[k] = 0.0

func _calculate_stat(stat_name: String, base_value: float) -> float:
	var final_val = base_value
	for p in passives:
		final_val = p.modify_stat(self, stat_name, final_val)
	return final_val
