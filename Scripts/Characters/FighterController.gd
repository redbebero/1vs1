extends CharacterBody2D

## FighterController: 전설적인 격투 게임 컨트롤러 (SOLID & Juice Optimized)
## P1/P2 시작 방향 설정 및 타격감 시스템 포함

# --- Signals ---
signal health_changed(id: int, current: float, max: float)
signal state_changed(old_state: State, new_state: State)

# --- Enums ---
enum State { IDLE, RUN, JUMP, FALL, ATTACK, STUN, DEAD }

# --- Export Variables ---
@export_group("Player Settings")
@export var player_id: int = 1 : 
	set(v):
		player_id = clamp(v, 1, 2)
		input_prefix = "p%d_" % player_id

@export_group("Combat Stats")
@export var character_data: CharacterData
@export var is_invincible: bool = false

# --- Internal Variables ---
var current_state: State = State.IDLE : set = _set_state
var current_hp: float = 100.0
var max_hp: float = 100.0
var input_prefix: String = "p1_"

# Stat values (Buffered from CharacterData)
var speed: float = 350.0
var acceleration: float = 2500.0
var friction: float = 1800.0
var jump_force: float = -700.0
var gravity_scale: float = 2.5

# --- Skill & Combat ---
var current_skill: Skill = null
var skill_timer: float = 0.0
var skill_phase: int = 0 # 0:Startup, 1:Active, 2:Recovery
var slot_cooldowns: Dictionary = {0: 0.0, 1: 0.0, 2: 0.0}
var active_hitboxes: Dictionary = {} # { HitboxData: Area2D }
var pending_hitboxes: Array[HitboxData] = []

# --- Component Refs ---
@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var animator: ProceduralAnimator = $ProceduralAnimator
@onready var visuals: StickmanVisuals = $StickmanVisuals

var opponent: CharacterBody2D

# --- Lifecycle ---
func _ready() -> void:
	add_to_group("Player")
	_initialize_controller()
	_find_opponent.call_deferred()

func _initialize_controller() -> void:
	# 시작 시 마주보기 설정 (P1: 오른쪽, P2: 왼쪽)
	if skeleton:
		skeleton.scale.x = 1.0 if player_id == 1 else -1.0
	
	if visuals:
		visuals.line_color = Color(0.2, 0.5, 1.0) if player_id == 1 else Color(1.0, 0.2, 0.2)
	
	# Global 데이터 주입 (Data Injection)
	var global = get_node_or_null("/root/Global")
	if not character_data and global:
		character_data = global.p1_data if player_id == 1 else global.p2_data
	
	if character_data:
		_apply_character_data()
	
	_connect_hud.call_deferred()

func _find_opponent() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	for p in players:
		if p != self and p is CharacterBody2D:
			opponent = p
			break

func _apply_character_data() -> void:
	# [RESTORED] VFX Registry Registration
	if character_data.vfx_registry:
		var vfx_data = character_data.vfx_registry.get("DATA")
		if vfx_data:
			VFXManager.register_vfx(vfx_data)

	max_hp = character_data.max_hp
	current_hp = max_hp
	speed = character_data.speed
	acceleration = character_data.acceleration
	friction = character_data.friction
	jump_force = character_data.jump_force
	gravity_scale = character_data.gravity_scale
	
	if visuals:
		visuals.equip_weapon("right", character_data.weapon_r_texture, character_data.weapon_scale_r, character_data.weapon_offset_r, character_data.weapon_rot_r)
		visuals.equip_weapon("left", character_data.weapon_l_texture, character_data.weapon_scale_l, character_data.weapon_offset_l, character_data.weapon_rot_l)
		if character_data.head_accessory_points.size() > 0:
			visuals.equip_head_accessory(character_data.head_accessory_points, character_data.head_accessory_color)

func _physics_process(delta: float) -> void:
	# State Machine Logic
	# Safety Check: 공격 상태인데 스킬이 없으면 강제로 종료 (버그 방지)
	if current_state == State.ATTACK and current_skill == null:
		_end_attack()
		
	_update_cooldowns(delta)
	
	match current_state:
		State.STUN:
			_apply_friction(delta)
		State.ATTACK:
			if current_skill: _process_attack(delta)
		State.DEAD:
			velocity = Vector2.ZERO
		_:
			_process_locomotion(delta)
			_update_facing()
	
	_apply_gravity(delta)
	move_and_slide()
	_update_animation()

# --- Core Logic: Locomotion ---
func _process_locomotion(delta: float) -> void:
	var move_dir = Input.get_axis(input_prefix + "left", input_prefix + "right")
	
	if move_dir != 0:
		velocity.x = move_toward(velocity.x, move_dir * speed, acceleration * delta)
		# 바닥에 있을 때만 RUN 상태, 공중이면 FALL/JUMP 유지
		if is_on_floor(): 
			current_state = State.RUN
	else:
		_apply_friction(delta)
		if is_on_floor(): 
			current_state = State.IDLE
	
	if is_on_floor() and Input.is_action_just_pressed(input_prefix + "up"):
		velocity.y = jump_force
		current_state = State.JUMP
		if visuals: visuals.spawn_jump_dust()
	
	if not is_on_floor():
		current_state = State.FALL if velocity.y > 0 else State.JUMP

	_handle_skill_input()

func _update_facing() -> void:
	# [FIX] Lock facing during attack to support directional skills
	if current_state == State.ATTACK or current_state == State.STUN:
		return

	# 이동 중일 때는 이동 방향을 우선함
	if abs(velocity.x) > 50:
		skeleton.scale.x = sign(velocity.x)
	# 정지 중일 때 상대를 바라보는 기능 제거됨

func _apply_friction(delta: float) -> void:
	var f = friction if is_on_floor() else 800.0
	velocity.x = move_toward(velocity.x, 0, f * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale * delta

# --- Core Logic: Combat & Skills ---
func _handle_skill_input() -> void:
	if not character_data: return
	
	var x = Input.get_axis(input_prefix + "left", input_prefix + "right")
	var y = Input.get_axis(input_prefix + "up", input_prefix + "down")
	var dir_key = "neutral"
	if abs(x) > 0.5: dir_key = "side"
	elif y < -0.5: dir_key = "up"
	elif y > 0.5: dir_key = "down"

	var skill: Skill = null
	var slot = -1
	
	if Input.is_action_just_pressed(input_prefix + "skill1"):
		skill = character_data.skill_a.get(dir_key)
		slot = 0
	elif Input.is_action_just_pressed(input_prefix + "skill2"):
		skill = character_data.skill_b.get(dir_key)
		slot = 1
	elif Input.is_action_just_pressed(input_prefix + "skill3"):
		skill = character_data.ult
		slot = 2
		
	if skill and slot_cooldowns[slot] <= 0:
		_start_attack(skill, slot)

func _start_attack(skill: Skill, slot: int) -> void:
	current_skill = skill
	current_state = State.ATTACK
	skill_timer = 0.0
	skill_phase = 0
	
	pending_hitboxes.clear()
	pending_hitboxes.append_array(skill.hitboxes)
	
	if slot >= 0: slot_cooldowns[slot] = skill.cooldown
	if skill.animation: animator.play_motion(skill.animation)
	velocity.x *= 0.1 # 공격 시 멈춤 효과

func _process_attack(delta: float) -> void:
	skill_timer += delta
	
	# Hitbox Spawning (Typed Array FIX)
	var still_pending: Array[HitboxData] = []
	for hb in pending_hitboxes:
		if skill_timer >= hb.delay: _spawn_hitbox(hb)
		else: still_pending.append(hb)
	pending_hitboxes = still_pending
	
	# Phase Transitions
	if skill_phase == 0 and skill_timer >= current_skill.startup_time:
		skill_phase = 1 # Active
		# [FIX] Only enable trail for Sword skills (Type A)
		if visuals and "Skill_A" in current_skill.resource_path:
			visuals.set_swing_trail(true, "left")
		
		if current_skill.vfx_on_active != "":
			VFXManager.spawn(current_skill.vfx_on_active, global_position, visuals.line_color, skeleton.scale.x)
		_apply_skill_tags()
		
	if skill_phase == 1 and skill_timer >= current_skill.startup_time + current_skill.active_duration:
		skill_phase = 2 # Recovery
		if visuals: visuals.set_swing_trail(false)
		_clear_all_hitboxes()

	if skill_timer >= current_skill.startup_time + current_skill.active_duration + current_skill.recovery_duration:
		_end_attack()

func _apply_skill_tags() -> void:
	var facing = skeleton.scale.x
	for tag in current_skill.tags:
		match tag:
			"dash": velocity.x = facing * 800
			"anti-air": velocity.y = -600
			"shockwave": visuals.spawn_shockwave()
			"grand_cross": visuals.spawn_grand_cross()

func _spawn_hitbox(hb: HitboxData) -> void:
	var area: Area2D
	if hb.type == HitboxData.HitboxType.ATTACHED:
		area = visuals.enable_hitbox(hb.attached_to)
	else:
		area = Area2D.new()
		var col = CollisionShape2D.new()
		if hb.shape == HitboxData.ShapeType.CIRCLE:
			var s = CircleShape2D.new(); s.radius = hb.size.x; col.shape = s
		else:
			var s = RectangleShape2D.new(); s.size = hb.size; col.shape = s
		area.add_child(col)
		add_child(area)
		area.position = Vector2(hb.offset.x * skeleton.scale.x, hb.offset.y)
	
	if area:
		area.set_meta("damage", current_skill.damage * hb.damage_multiplier)
		area.set_meta("knockback", current_skill.knockback * hb.knockback_multiplier)
		area.set_meta("stun", current_skill.stun_duration)
		area.set_meta("source_name", hb.name)
		if not area.body_entered.is_connected(_on_hitbox_entered):
			area.body_entered.connect(_on_hitbox_entered.bind(area))
		active_hitboxes[hb] = area

func _on_hitbox_entered(body: Node, hitbox: Area2D) -> void:
	if body != self and body.has_method("take_damage"):
		var dmg = hitbox.get_meta("damage", 10.0)
		var kb = hitbox.get_meta("knockback", Vector2.ZERO) * Vector2(skeleton.scale.x, 1.0)
		var s_name = hitbox.get_meta("source_name", "")
		var stun = hitbox.get_meta("stun", 0.3)
		
		body.take_damage(dmg, global_position, kb, stun)
		
		# VFX & Juice
		var vfx_pos = body.global_position + Vector2(0, -40)
		VFXManager.spawn("hit_impact", vfx_pos, Color.WHITE)
		if "Sword" in s_name:
			VFXManager.spawn("neon_sparks", vfx_pos, visuals.line_color * 2.5, skeleton.scale.x)
			VFXManager.shake_camera(0.2)
		elif "Shield" in s_name:
			VFXManager.spawn("impact_shockwave", vfx_pos, visuals.line_color * 1.5)
			VFXManager.shake_camera(0.5)
		
		hitbox.set_deferred("monitoring", false)

func _clear_all_hitboxes() -> void:
	for hb in active_hitboxes.keys():
		var area = active_hitboxes[hb]
		if hb.type == HitboxData.HitboxType.ATTACHED: visuals.disable_all_hitboxes()
		else: area.queue_free()
	active_hitboxes.clear()

func _end_attack() -> void:
	current_skill = null
	current_state = State.IDLE
	if visuals: visuals.set_swing_trail(false)
	_clear_all_hitboxes()

# --- Combat & Damage ---
func take_damage(amount: float, attacker_pos: Vector2, knockback: Vector2, stun_time: float) -> void:
	if is_invincible or current_state == State.DEAD: return
	
	current_hp -= amount
	health_changed.emit(player_id, current_hp, max_hp)
	
	if visuals: visuals.apply_hit_flash()
	VFXManager.start_hit_impact(0.1, 0.2, 0.4) # Freeze, Slow, Shake
	
	if current_hp <= 0:
		_die()
	else:
		_enter_stun(stun_time, knockback)

func _enter_stun(time: float, kb: Vector2) -> void:
	current_state = State.STUN
	velocity = kb
	_end_attack()
	await get_tree().create_timer(time).timeout
	if current_state == State.STUN: current_state = State.IDLE

func _die() -> void:
	current_state = State.DEAD
	print("P%d Defeated" % player_id)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# --- Animation & Helpers ---
func _set_state(new_state: State) -> void:
	if current_state == new_state: return
	var old = current_state
	current_state = new_state
	state_changed.emit(old, new_state)

func _update_animation() -> void:
	if not animator or current_state == State.ATTACK: return
	var n = State.keys()[current_state].capitalize()
	animator.update_state(n, velocity, is_on_floor())

func _update_cooldowns(delta: float) -> void:
	for k in slot_cooldowns.keys():
		if slot_cooldowns[k] > 0: slot_cooldowns[k] -= delta

func _connect_hud() -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("update_health"):
		health_changed.connect(hud.update_health)
		health_changed.emit(player_id, current_hp, max_hp)
