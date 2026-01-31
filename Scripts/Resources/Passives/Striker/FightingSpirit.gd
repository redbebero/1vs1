class_name FightingSpirit
extends Passive

## 투지: 체력 20% 이하 시 데미지 +15 고정 증가

func on_ready(_fighter):
	passive_name = "Fighting Spirit"

func on_deal_damage(fighter, _target, amount):
	var hp_ratio = fighter.current_hp / fighter.max_hp
	if hp_ratio <= 0.2:
		return amount + 15.0
	return amount
