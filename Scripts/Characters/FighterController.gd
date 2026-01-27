extends CharacterBody2D

## 1대1 격투 게임 캐릭터 컨트롤러
## 물리 이동과 입력 처리를 담당하며, 애니메이션은 ProceduralAnimator에게 위임합니다.

@export_group("Player Settings")
@export var player_id: int = 1 : 
	set(v):
		player_id = clamp(v, 1, 2)
		input_prefix = "p%d_" % player_id

@export_group("Data")
@export var character_data: CharacterData

# 하위 호환성을 위해 character_data가 없을 경우 기본값 사용 (옵션)
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

func _ready() -> void:
	if visuals:
		if player_id == 1:
			visuals.line_color = Color(0.2, 2.0, 2.5) # Cyber Cyan
		else:
			visuals.line_color = Color(2.5, 0.2, 2.0) # Hot Magenta

func _apply_character_data() -> void:
	speed = character_data.speed
	acceleration = character_data.acceleration
	friction = character_data.friction
	jump_force = character_data.jump_force
	air_resistance = character_data.air_resistance
	gravity_scale = character_data.gravity_scale
	
	if visuals:
		visuals.line_color = character_data.color
		visuals.head_radius = character_data.head_radius
		visuals.line_width = character_data.line_width

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)
	handle_jump()
	move_and_slide()
	
	# 애니메이션 상태 업데이트 (위임)
	_update_animation_state()

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

# --- 애니메이션 상태 결정 로직 ---
func _update_animation_state() -> void:
	if not animator: return
	
	var state_name = "Idle"
	
	if is_on_floor():
		if abs(velocity.x) > 20:
			state_name = "Run"
		else:
			state_name = "Idle"
	else:
		if velocity.y < 0:
			state_name = "Jump"
		else:
			state_name = "Fall"
	
	# Animator에게 현재 상태와 물리 정보 전달
	animator.update_state(state_name, velocity, is_on_floor())
