class_name HitboxData
extends Resource

enum HitboxType { FIXED, EXPANDING, ATTACHED, PROJECTILE }
enum ShapeType { RECTANGLE, CIRCLE }

@export var name: String = "Hitbox"
@export var type: HitboxType = HitboxType.FIXED
@export var shape: ShapeType = ShapeType.RECTANGLE

@export var size: Vector2 = Vector2(100, 100)
@export var offset: Vector2 = Vector2.ZERO
@export var attached_to: String = "" # Bone name or node name

@export var delay: float = 0.0 # Delay from skill start
@export var duration: float = 0.2
@export var expansion_duration: float = 0.3 # For EXPANDING type

@export var damage: float = 10.0
@export var stun: float = 0.2
@export var knockback_force: float = 400.0
@export var damage_multiplier: float = 1.0
@export var knockback_multiplier: float = 1.0

@export var projectile_speed: float = 0.0
@export var projectile_direction: Vector2 = Vector2.RIGHT
