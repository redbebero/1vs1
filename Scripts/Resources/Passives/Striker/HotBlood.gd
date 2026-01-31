class_name HotBlood
extends Passive

## 열혈: 공격 적중 시 공속 5% 증가 (최대 30%)
## 여기서는 단순화를 위해 스킬의 타이밍 비율을 직접 수정하거나 FighterController에 변수를 둡니다.

var stacks: int = 0
var max_stacks: int = 6

func on_ready(_fighter):
	passive_name = "Hot Blood"

func on_attack_hit(fighter, _target):
	if stacks < max_stacks:
		stacks += 1
		# FighterController에 speed_multiplier 같은 변수가 있다고 가정하거나
		# 간단히 로그를 찍고 나중에 통합합니다.
		print("Hot Blood Stacks: ", stacks)

func modify_stat(_fighter, stat_name, base_value):
	if stat_name == "attack_speed":
		return base_value * (1.0 + (stacks * 0.05))
	return base_value
