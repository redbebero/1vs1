class_name StickmanVisuals
extends Node2D

## Skeleton2D의 Bone2D들을 실시간으로 연결하여 선(Line)으로 그려주는 스크립트입니다.
## 머리는 속이 빈 원으로, 팔다리는 관절이 있는 선으로 표현합니다.

@export var skeleton_path: NodePath = "../Skeleton2D"
@onready var skeleton: Skeleton2D = get_node_or_null(skeleton_path)

@export_group("Visual Style")
@export var line_color: Color = Color(0.2, 2.0, 2.5) # 네온 느낌의 밝은 하늘색 (HDR)
@export var line_width: float = 6.0
@export var joint_size: float = 4.0
@export var head_radius: float = 14.0 # 머리 크기 살짝 키움
@export var head_bone_name: String = "Head" 

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
				
				# 머리는 특별 취급 (속이 빈 원)
				# 정확히 이름이 일치할 때만 그림 (HeadEnd 등이 포함되는 것 방지)
				if child.name == head_bone_name:
					# 머리 뼈 위치에 속이 빈 원 그리기
					# 0 ~ 360(TAU)도, 해상도 32
					draw_arc(child_pos, head_radius, 0, TAU, 32, line_color, line_width, true)
				else:
					# 그 외(몸통, 팔, 다리)는 선으로 연결
					# End Bone은 그리지 않음 (손끝/발끝 연장 제거)
					if not "End" in child.name:
						draw_line(parent_pos, child_pos, line_color, line_width, true)
						# 관절 원(draw_circle) 제거됨
			
			draw_bones_recursive(child)

# --- VFX Spawning (Procedural) ---

func spawn_step_dust(direction_x: float) -> void:
	var p = _create_base_particle(line_color, 4) # Player Color
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(5, 2)
	p.direction = Vector2(-direction_x, -0.5) # Kick back
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.lifetime = 0.3
	
	add_child(p)
	p.position = Vector2(0, 0) # Ground level
	p.emitting = true

func spawn_jump_dust() -> void:
	var p = _create_base_particle(line_color, 16) # 양 늘림
	p.direction = Vector2(0, 1) # Down
	p.spread = 120.0 # 더 넓게 퍼짐 (30.0 -> 120.0)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 200.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.lifetime = 0.4
	p.explosiveness = 1.0
	
	add_child(p)
	p.position = Vector2(0, 0) # Ground level
	p.emitting = true

func spawn_land_dust() -> void:
	var p = _create_base_particle(line_color, 20) # Player Color
	p.direction = Vector2(0, -1) # Up/Side
	p.spread = 90.0
	p.gravity = Vector2(0, 100)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 180.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	p.lifetime = 0.5
	p.explosiveness = 1.0
	
	add_child(p)
	p.position = Vector2(0, 0) # Ground level
	p.emitting = true

func _create_base_particle(color: Color, amount: int) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.color = color
	p.scale_amount_curve = _get_shrink_curve()
	
	# Auto-destroy using Timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(p.queue_free)
	p.add_child(timer)
	
	return p

func _get_shrink_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	return curve