class_name CharacterData
extends Resource

## 캐릭터의 기본 스탯과 비주얼 설정을 담는 데이터 리소스입니다.
## 45개 직업 확장을 위해 각 직업마다 이 리소스를 생성하여 FighterController에 할당합니다.

@export_group("Stats")
@export var max_hp: float = 100.0
@export var regen: float = 0.0
@export var speed: float = 350.0
@export var acceleration: float = 2500.0
@export var friction: float = 1800.0
@export var jump_force: float = -700.0
@export var air_resistance: float = 800.0
@export var gravity_scale: float = 2.5
@export var poise: float = 0.0 # Max Poise
@export var damage_reduction: float = 0.0 # Percentage (0.0 - 1.0)
@export var hurtbox_size: Vector2 = Vector2(40, 80)

@export_group("Visuals")
@export var color: Color = Color(0.2, 2.0, 2.5)
@export var head_radius: float = 14.0
@export var line_width: float = 6.0
@export var weapon_l_texture: Texture2D
@export var weapon_r_texture: Texture2D
@export var weapon_scale: Vector2 = Vector2(0.5, 0.5)
@export var weapon_scale_l: Vector2 = Vector2(0.5, 0.5) 
@export var weapon_scale_r: Vector2 = Vector2(0.5, 0.5)
@export var weapon_offset_l: Vector2 = Vector2.ZERO

@export var weapon_offset_r: Vector2 = Vector2(20, 0)
@export var passives: Array[Script] = [] # List of Passive GDScripts to instantiate


@export_group("Skills")
## Skill A (Key 1): Mapping "neutral", "side", "up", "down" -> Skill Resource
@export var skill_a: Dictionary = {
	"neutral": null,
	"side": null,
	"up": null,
	"down": null
}

## Skill B (Key 2): Mapping "neutral", "side", "up", "down" -> Skill Resource
@export var skill_b: Dictionary = {
	"neutral": null,
	"side": null,
	"up": null,
	"down": null
}

## Ultimate (Key 3): Single Skill Resource
@export var ult: Resource
