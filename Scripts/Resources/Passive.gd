class_name Passive
extends Resource

## Base Class for all Character Passives
## Passives are Resources that hook into the FighterController's events.
## Override these functions to implement specific logic.

@export var passive_name: String = "Passive"
@export var description: String = ""

# --- Hooks ---

## Called when the fighter is ready or when passive is added
func on_ready(fighter: CharacterBody2D) -> void:
	pass

## Called every frame (process)
func on_process(fighter: CharacterBody2D, delta: float) -> void:
	pass

## Called when the fighter deals damage to a target
## Return the modified damage amount
func on_deal_damage(fighter: CharacterBody2D, target: CharacterBody2D, amount: float) -> float:
	return amount

## Called when the fighter takes damage from a source
## Return the modified damage amount
func on_take_damage(fighter: CharacterBody2D, source: Node2D, amount: float) -> float:
	return amount

## Called when the fighter is hit (after damage calculation)
func on_hit(fighter: CharacterBody2D, source: Node2D) -> void:
	pass

## Called when the fighter hits an enemy
func on_attack_hit(fighter: CharacterBody2D, target: CharacterBody2D) -> void:
	pass

## Called to modify a specific stat (e.g. "speed", "poise")
## Return the modified stat value
func modify_stat(fighter: CharacterBody2D, stat_name: String, base_value: float) -> float:
	return base_value
