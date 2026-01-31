extends Line2D

@export var max_points: int = 15
@export var target_node: Node2D # 검의 끝부분(Tip) 노드
@export var base_node: Node2D   # 검의 손잡이(Base) 노드

var points_top: Array[Vector2] = []
var points_bottom: Array[Vector2] = []

func _ready():
	top_level = true # 부모의 회전에 영향을 받지 않음
	z_index = 5
	antialiased = true

func _process(_delta):
	if not target_node or not is_visible_in_tree():
		clear_points()
		return

	# 현재 무기 위치 기록
	var pos_top = target_node.global_position
	points_top.push_front(pos_top)
	
	if points_top.size() > max_points:
		points_top.pop_back()

	# Line2D 포인트를 업데이트 (간단하게 끝점만 연결하거나 Polygon2D로 확장 가능)
	# 여기서는 Line2D의 기본 기능을 활용해 궤적을 그립니다.
	points = points_top

func clear_trail():
	points_top.clear()
	points = []
