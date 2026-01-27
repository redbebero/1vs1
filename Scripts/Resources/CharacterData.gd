class_name CharacterData
extends Resource

## 캐릭터의 기본 스탯과 비주얼 설정을 담는 데이터 리소스입니다.
## 45개 직업 확장을 위해 각 직업마다 이 리소스를 생성하여 FighterController에 할당합니다.

@export_group("Stats")
@export var hp: float = 100.0
@export var speed: float = 350.0
@export var acceleration: float = 2500.0
@export var friction: float = 1800.0
@export var jump_force: float = -700.0
@export var air_resistance: float = 800.0
@export var gravity_scale: float = 2.5
@export var poise: float = 0.0

@export_group("Visuals")
@export var color: Color = Color(0.2, 2.0, 2.5)
@export var head_radius: float = 14.0
@export var line_width: float = 6.0
