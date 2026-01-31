extends Node

# Global Singleton for Game State

# 플레이어가 선택한 데이터를 저장 (P1, P2)
# 타입 힌트를 제거하여 로딩 시점의 의존성 문제를 해결합니다.
var p1_data = null
var p2_data = null

# 직업 리스트 (이름: 데이터경로)
var character_list: Dictionary = {
	"Knight": "res://Scripts/Resources/Characters/Knight/Knight_Data.tres",
	"Striker": "res://Scripts/Resources/Characters/Striker/Striker_Data.tres"
}

func get_character_data(char_name: String):
	if character_list.has(char_name):
		var res = load(character_list[char_name])
		return res
	return null
