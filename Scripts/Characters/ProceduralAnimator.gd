class_name ProceduralAnimator
extends Node

## 절차적 애니메이션 관리자 (Legendary Edition)
## 특징: 관성(Inertia) 시뮬레이션 및 인체공학적 교차 보행 구현

# --- 설정 ---
@export var skeleton_path: NodePath = "../Skeleton2D"
@export var visuals_path: NodePath = "../StickmanVisuals"
@export var anim_speed: float = 12.0 
@export var lean_strength: float = 0.2 # 걷기: 거의 숙이지 않음 (0.8 -> 0.2)

# [System] Stance Configuration (Knight / Jet Style)
@export_group("Stance System")
@export var stance_arm_r_angle: float = 1.1   # 5시 방향 (겨드랑이 좁힘)
@export var stance_arm_l_angle: float = 5.2   # 11시 방향 (겨드랑이 좁힘)
@export var stance_forearm_r_angle: float = -1.6 # 앞팔: 각도를 넓게 (접힘 완화)
@export var stance_forearm_l_angle: float = -2.0 # 뒷팔: 각도를 조금 더 크게(여유)

# --- 내부 변수 ---
var _skeleton: Skeleton2D
var _visuals: StickmanVisuals
var _anim_time: float = 0.0
var _last_step_phase: int = 0

var _current_state: String = "Idle"
var _velocity: Vector2 = Vector2.ZERO
var _is_on_floor: bool = true
var _procedural_influence: float = 1.0 

# MotionData 재생용 변수
var _current_motion: MotionData = null
var _motion_step_index: int = 0
var _motion_step_time: float = 0.0
var _motion_targets: Dictionary = {}

# 뼈 노드 캐싱
var _bones: Dictionary = {}
var _state_handlers: Dictionary = {}

func _ready() -> void:
	_skeleton = get_node_or_null(skeleton_path)
	_visuals = get_node_or_null(visuals_path)
	if not _skeleton: return
	_cache_bones()
	_register_states()

func _process(delta: float) -> void:
	if not _skeleton: return
	
	if _current_motion:
		_process_motion(delta)
		return

	if _procedural_influence <= 0.01:
		return
		
	var speed_scale = 1.0
	if _current_state == "Run":
		speed_scale = clamp(abs(_velocity.x) / 300.0, 0.8, 1.5)
	
	_anim_time += delta * anim_speed * speed_scale
	
	if _current_state in _state_handlers:
		_state_handlers[_current_state].call(delta)

# --- MotionData Logic ---
func play_motion(data: MotionData) -> void:
	if not data or data.steps.is_empty(): return
	_current_motion = data
	_motion_step_index = 0
	_motion_step_time = 0.0
	_setup_motion_step()

func stop_motion() -> void:
	_current_motion = null
	_motion_targets.clear()

func _process_motion(delta: float) -> void:
	if not _current_motion: return
	var step = _current_motion.steps[_motion_step_index]
	var duration = step.get("duration", 0.1)
	_motion_step_time += delta
	var t = clamp(_motion_step_time / duration, 0.0, 1.0)
	for bone_name in _motion_targets:
		var target_rot = _motion_targets[bone_name]
		_lerp_bone_rot(bone_name, target_rot, 15.0 * delta)
	if _motion_step_time >= duration:
		_motion_step_index += 1
		if _motion_step_index >= _current_motion.steps.size():
			if _current_motion.is_loop:
				_motion_step_index = 0
				_motion_step_time = 0.0
				_setup_motion_step()
			else:
				stop_motion()
		else:
			_motion_step_time = 0.0
			_setup_motion_step()

func _setup_motion_step() -> void:
	var step = _current_motion.steps[_motion_step_index]
	_motion_targets.clear()
	for key in step:
		if key == "duration" or key == "ease": continue
		if key in _bones:
			_motion_targets[key] = step[key]

func update_state(state: String, velocity: Vector2, on_floor: bool) -> void:
	if _current_motion and state != "Hit": 
		pass 
	else:
		# 상태 변경 감지 및 이펙트 재생
		if _visuals and _current_state != state:
			if state == "Jump":
				_visuals.spawn_jump_dust()
			elif (state == "Idle" or state == "Run") and (_current_state == "Fall" or _current_state == "Jump"):
				_visuals.spawn_land_dust()
		
		_current_state = state
	_velocity = velocity
	_is_on_floor = on_floor

func set_procedural_influence(amount: float) -> void:
	_procedural_influence = clamp(amount, 0.0, 1.0)

func _cache_bones() -> void:
	var bone_paths = [
		"Hip", "Hip/Torso", "Hip/Torso/Head",
		"Hip/Torso/ArmL", "Hip/Torso/ArmL/ForeArmL",
		"Hip/Torso/ArmR", "Hip/Torso/ArmR/ForeArmR",
		"Hip/ThighL", "Hip/ThighL/ShinL",
		"Hip/ThighR", "Hip/ThighR/ShinR"
	]
	for path in bone_paths:
		var node = _skeleton.get_node_or_null(path)
		if node:
			var key = path.split("/")[-1]
			_bones[key] = node

func _register_states() -> void:
	_state_handlers["Idle"] = _animate_idle
	_state_handlers["Run"] = _animate_run
	_state_handlers["Jump"] = _animate_jump
	_state_handlers["Fall"] = _animate_fall

# --- [Core System] Upper Body Stance Logic ---
func _apply_upper_body(delta: float, swing_offset_r: float, swing_offset_l: float) -> void:
	var target_r = stance_arm_r_angle + swing_offset_r
	var target_l = stance_arm_l_angle + swing_offset_l
	
	# ForeArms: 비대칭 적용
	var target_fore_r = stance_forearm_r_angle
	var target_fore_l = stance_forearm_l_angle
	
	_lerp_bone_rot("ArmR", target_r, delta * 15.0)
	_lerp_bone_rot("ArmL", target_l, delta * 15.0)
	_lerp_bone_rot("ForeArmR", target_fore_r, delta * 15.0)
	_lerp_bone_rot("ForeArmL", target_fore_l, delta * 15.0)


# --- Animation States ---

func _animate_idle(delta: float) -> void:
	var breath = sin(_anim_time * 0.4)
	
	_lerp_bone_rot("Torso", breath * 0.03, delta * 5.0)
	_lerp_bone_rot("Head", -breath * 0.03, delta * 5.0)
	
	_lerp_bone_rot("ThighL", -0.4, delta * 10.0)
	_lerp_bone_rot("ShinL", 0.4, delta * 10.0)
	_lerp_bone_rot("ThighR", 0.3, delta * 10.0)
	_lerp_bone_rot("ShinR", 0.1, delta * 10.0)
	_lerp_bone_pos_y("Hip", -45.0 + breath * 2.0, delta * 5.0)
	
	_apply_upper_body(delta, -breath * 0.02, breath * 0.02)

func _animate_run(delta: float) -> void:
	var t = _anim_time
	var run_blend = 10.0 * delta # 걷기는 전이가 조금 더 부드러움
	
	var current_phase = int(t / PI)
	if current_phase > _last_step_phase:
		_last_step_phase = current_phase
		if _visuals:
			_visuals.spawn_step_dust(sign(_velocity.x))

	# 1. 몸통: 가벼운 걷기 (거의 서 있음)
	_lerp_bone_rot("Torso", lean_strength, run_blend)
	_lerp_bone_rot("Head", 0.0, run_blend) # 정면 응시 (회전 없음)
	
	# 2. 하체: Majestic Walk (위엄 있는 걷기)
	var l_phase = sin(t)
	var r_phase = sin(t + PI)
	
	# 허벅지: 보폭을 시원시원하게 넓힘
	var thigh_amp_fwd = -1.2
	var thigh_amp_back = 1.2 # 뒷다리 각도 확장
	
	var l_norm = (l_phase + 1.0) * 0.5 
	var r_norm = (r_phase + 1.0) * 0.5
	
	_lerp_bone_rot("ThighL", lerp(thigh_amp_back, thigh_amp_fwd, l_norm), run_blend)
	_lerp_bone_rot("ThighR", lerp(thigh_amp_back, thigh_amp_fwd, r_norm), run_blend)
	
	# 정강이: 자연스러운 굽힘 (50% 정도)
	var shin_fold = 0.8
	var shin_l_t = 0.5
	if l_phase > 0: shin_l_t = shin_fold * l_phase
	var shin_r_t = 0.5
	if r_phase > 0: shin_r_t = shin_fold * r_phase
	
	_lerp_bone_rot("ShinL", shin_l_t, run_blend)
	_lerp_bone_rot("ShinR", shin_r_t, run_blend)
	
	# 3. 힙: 미세한 바운스
	var bounce = abs(cos(t)) * -2.0 
	_lerp_bone_pos_y("Hip", -45.0 + bounce, run_blend)
	
	# 4. 상체: 여유로운 스윙
	var arm_swing = cos(t) * 0.4 
	_apply_upper_body(delta, arm_swing, -arm_swing)

func _animate_jump(delta: float) -> void:
	var jump_blend = 20.0 * delta
	_lerp_bone_rot("Torso", 0.2, jump_blend)
	
	# 점프: 니킥 자세 강화
	_lerp_bone_rot("ThighL", -1.8, jump_blend) # 더 높게
	_lerp_bone_rot("ShinL", 2.2, jump_blend)   # 꽉 접음
	_lerp_bone_rot("ThighR", 0.6, jump_blend)
	_lerp_bone_rot("ShinR", 0.1, jump_blend)
	
	# 상체: 점프 중에도 스탠스 유지 (스윙 없음)
	_apply_upper_body(delta, 0.0, 0.0)

func _animate_fall(delta: float) -> void:
	var fall_blend = 10.0 * delta
	_lerp_bone_rot("Torso", 0.1, fall_blend)
	
	_lerp_bone_rot("ThighL", -0.3, fall_blend)
	_lerp_bone_rot("ShinL", 0.5, fall_blend)
	_lerp_bone_rot("ThighR", 0.2, fall_blend)
	_lerp_bone_rot("ShinR", 0.2, fall_blend)
	
	# 상체: 낙하 중에는 팔을 살짝 벌려 균형 잡기 (스탠스 변형)
	# 여기서는 예외적으로 스탠스보다 조금 더 벌림
	var fall_offset = -0.3
	_apply_upper_body(delta, fall_offset, fall_offset)

# --- 유틸리티 ---
func _lerp_bone_rot(key: String, target: float, speed: float) -> void:
	if key in _bones:
		var current_rot = _bones[key].rotation
		var next_rot = lerp_angle(current_rot, target, speed)
		if _procedural_influence < 1.0:
			_bones[key].rotation = lerp_angle(current_rot, next_rot, _procedural_influence)
		else:
			_bones[key].rotation = next_rot

func _lerp_bone_pos_y(key: String, target: float, speed: float) -> void:
	if key in _bones:
		var current_y = _bones[key].position.y
		var next_y = move_toward(current_y, target, speed)
		if _procedural_influence < 1.0:
			_bones[key].position.y = lerp(current_y, next_y, _procedural_influence)
		else:
			_bones[key].position.y = next_y
