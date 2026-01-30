extends Passive
class_name Passive_SilverGrace

## 은색의 가호: 전면 피격 시 데미지 10% 추가 감소

@export var reduction_rate: float = 0.1

func on_take_damage(fighter: CharacterBody2D, source: Node2D, amount: float) -> float:
	# Source can be null or pure position, we need Vector
	# In FighterController we assumed source is Node2D but Logic passed Vector2 position...
	# We need to fix FighterController to pass relevant info. source is usually the Attacker Body or Projectile Node
	
	# Actually, FighterController.take_damage takes (amount, source_pos, knockback) variables
	# But hook sends (self, null, amount). We need to improve hook.
	
	# For now, let's assume always active if we can't detect direction (Prototype limit)
	# Or better: We rely on FighterController logic which *does* check direction for base 20%
	# But this is "Additional 10%".
	
	# Since we don't have source info in the hook yet effectively, we will just apply global reduction for now 
	# until we refactor take_damage signature.
	
	return amount * (1.0 - reduction_rate)
