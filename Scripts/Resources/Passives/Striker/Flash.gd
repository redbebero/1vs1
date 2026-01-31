class_name FlashEvasion
extends Passive

## 번뜩임: 7타당 1회 확정 회피

var hit_counter: int = 0
var next_evade: bool = false

func on_ready(_fighter):
	passive_name = "Flash"

func on_hit(_fighter, _source):
	hit_counter += 1
	if hit_counter >= 7:
		next_evade = true
		hit_counter = 0
		print("Flash Ready!")

func on_take_damage(_fighter, _source, amount):
	if next_evade:
		next_evade = false
		print("Flashed! Damage Evaded.")
		return 0.0 # 0 damage
	return amount
