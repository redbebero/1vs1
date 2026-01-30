extends Passive
class_name Passive_PerfectDefense

## 완벽한 방어: 4타 적중 시 다음 피격 1회 0 데미지 실드 생성

var hit_count: int = 0
var shield_active: bool = false
@export var required_hits: int = 4

func on_ready(fighter: CharacterBody2D) -> void:
    hit_count = 0
    shield_active = false

func on_attack_hit(fighter: CharacterBody2D, target: CharacterBody2D) -> void:
    if shield_active:
        return # Already has shield
        
    hit_count += 1
    if hit_count >= required_hits:
        hit_count = 0
        shield_active = true
        print("[Perfect Defense] Shield Activated!")
        # Visual cue? fighter.visuals.set_color(GOLD)...

func on_take_damage(fighter: CharacterBody2D, source: Node2D, amount: float) -> float:
    if shield_active:
        shield_active = false
        print("[Perfect Defense] Damage blocked!")
        return 0.0
    return amount
