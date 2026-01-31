class_name Skill
extends Resource

## Base class for all character skills.
## Encapsulates logic, animation, and data for a specific move.
## Prevents FighterController from becoming a "God Object".

@export var skill_name: String = "Base Skill"
@export var cooldown: float = 0.0
@export_group("Timing")
@export var startup_time: float = 0.1 # Windup time before active
@export var active_duration: float = 0.2 # Duration of active phase
@export var recovery_duration: float = 0.3 # Duration of recovery phase

@export var animation: MotionData
@export var can_cancel: bool = true # Can this skill be cancelled into another skill during recovery?

@export_group("Combat")
@export var hitboxes: Array[HitboxData] = []
@export var damage: float = 10.0
@export var knockback: Vector2 = Vector2.ZERO
@export var stun_duration: float = 0.2

@export_group("Visuals")
@export var tags: Array[String] = [] # e.g., "low", "anti-air", "shockwave", "grand_cross"
@export var vfx_on_start: String = ""
@export var vfx_on_active: String = ""

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
