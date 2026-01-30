class_name VFXRegistry
extends RefCounted

## The Encyclopedia of Visual Effects
## All effect parameters are defined here.
## Returns a Dictionary containing parameters for VFXManager to consume.

const DATA: Dictionary = {
	"hit_impact": {
		"amount": 32,
		"lifetime": 0.5,
		"explosiveness": 1.0,
		"spread": 180.0,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 250.0, 
		"initial_velocity_max": 500.0,
		"scale_amount_min": 4.0,
		"scale_amount_max": 8.0,
		"damping_min": 300.0,
		"damping_max": 500.0
	},
	"block_spark": {
		"amount": 24,
		"lifetime": 0.4,
		"explosiveness": 1.0,
		"spread": 80.0,
		"gravity": Vector2(0, 800), # Stronger fall
		"initial_velocity_min": 300.0, 
		"initial_velocity_max": 600.0,
		"scale_amount_min": 3.0,
		"scale_amount_max": 5.0,
		"direction": Vector2(-1, -1)
	},
	"step_dust": {
		"amount": 8,
		"lifetime": 0.5,
		"explosiveness": 0.8,
		"spread": 30.0,
		"gravity": Vector2(0, -100),
		"initial_velocity_min": 30.0,
		"initial_velocity_max": 80.0,
		"scale_amount_min": 3.0,
		"scale_amount_max": 6.0,
		"direction": Vector2(-1, 0.2)
	},
	"dash_smoke": {
		"amount": 20,
		"lifetime": 0.6,
		"explosiveness": 0.1,
		"spread": 20.0,
		"gravity": Vector2(0, -40),
		"initial_velocity_min": 80.0,
		"initial_velocity_max": 150.0,
		"scale_amount_min": 5.0,
		"scale_amount_max": 10.0,
		"direction": Vector2(-1, 0)
	},
	"jump_dust": {
		"amount": 16,
		"lifetime": 0.5,
		"explosiveness": 1.0,
		"spread": 120.0,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 100.0,
		"initial_velocity_max": 200.0,
		"scale_amount_min": 4.0,
		"scale_amount_max": 7.0,
		"direction": Vector2(0, 1)
	},
	"land_dust": {
		"amount": 20,
		"lifetime": 0.5,
		"explosiveness": 1.0,
		"spread": 180.0,
		"gravity": Vector2(0, -20),
		"initial_velocity_min": 150.0,
		"initial_velocity_max": 250.0,
		"scale_amount_min": 4.0,
		"scale_amount_max": 8.0
	},
	# Knight Specific
	"knight_slash": {
		"amount": 40,
		"lifetime": 0.35,
		"explosiveness": 0.4,
		"spread": 15.0,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 400.0,
		"initial_velocity_max": 700.0,
		"scale_amount_min": 3.0,
		"scale_amount_max": 5.0,
		"direction": Vector2(1, 0)
	},
	"shockwave": {
		"amount": 50,
		"lifetime": 1.0,
		"explosiveness": 1.0,
		"spread": 180.0,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 800.0,
		"initial_velocity_max": 1200.0,
		"scale_amount_min": 15.0,
		"scale_amount_max": 30.0,
		"damping_min": 1000.0,
		"damping_max": 1500.0,
		"z_index": 10
	}
}

static func get_data(effect_name: String) -> Dictionary:
	return DATA.get(effect_name, {})
