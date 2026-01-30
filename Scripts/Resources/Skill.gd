class_name Skill
extends Resource

## Base class for all character skills.
## Encapsulates logic, animation, and data for a specific move.
## Prevents FighterController from becoming a "God Object".

@export var skill_name: String = "Base Skill"
@export var cooldown: float = 0.0
@export var startup_time: float = 0.0 # Windup time before active
@export var animation: MotionData
@export var can_cancel: bool = true # Can this skill be cancelled into another skill during recovery?

@export_group("Combat")
enum HitboxType { FIXED, EXPANDING }
enum ShapeType { RECTANGLE, CIRCLE }
@export var hitbox_type: HitboxType = HitboxType.FIXED
@export var shape_type: ShapeType = ShapeType.RECTANGLE
@export var expansion_duration: float = 0.3 # Time it takes to reach full size
@export var hitbox_name: String = "" # Empty = Fixed, "weapon_l", "weapon_r", etc.
@export var damage: float = 0.0
@export var hitbox_size: Vector2 = Vector2(0, 0)
@export var hitbox_offset: Vector2 = Vector2(50, 0) # Relative to character center
@export var knockback: Vector2 = Vector2.ZERO
@export var stun_duration: float = 0.0
@export var is_unblockable: bool = false
@export var is_projectile: bool = false
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 0.0
@export var tags: Array[String] = [] # e.g., "low", "anti-air", "buff"

@export_group("Buffs/Status")
@export var self_buff_duration: float = 0.0
@export var damage_reduction_mod: float = 0.0
@export var poise_mod: float = 0.0

# Runtime state (not serialized)
var _current_cooldown: float = 0.0

## Called when the skill is first activated
## Returns true if activation was successful
func enter(fighter: CharacterBody2D) -> void:
	if animation and fighter.has_method("play_motion"):
		fighter.play_motion(animation)
	# Override this to add logic (hitboxes, effects, etc.)

## Called when the skill ends (interrupted or finished)
func exit(fighter: CharacterBody2D) -> void:
	pass
