class_name MotionData
extends Resource

## 절차적 애니메이션을 위한 "숫자 파일" (Data-Driven Motion)
## 키프레임 방식이 아닌, 상태 전이(State Transition) 데이터를 정의합니다.
## 각 단계(Step)는 목표 각도와 도달 시간을 가집니다.

@export var motion_name: String = "Skill"
@export var is_loop: bool = false

## 각 단계의 설정 값 (Array of Dictionaries)
## 예: { "duration": 0.2, "ArmR": -1.5, "Torso": 0.5, "ease": "ease_out" }
@export var steps: Array[Dictionary] = []
