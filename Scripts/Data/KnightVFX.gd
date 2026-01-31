class_name KnightVFX
extends RefCounted

const DATA: Dictionary = {
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
	},
	"knight_ult_core": {
		"amount": 1,
		"lifetime": 0.5,
		"explosiveness": 1.0,
		"spread": 0.0,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 0.0,
		"initial_velocity_max": 0.0,
		"scale_amount_min": 150.0,
		"scale_amount_max": 200.0,
		"z_index": 20
	},
	"knight_ult_beam": {
		"amount": 120,
		"lifetime": 0.8,
		"explosiveness": 0.95,
		"spread": 1.5,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 1500.0,
		"initial_velocity_max": 3500.0,
		"scale_amount_min": 8.0,
		"scale_amount_max": 20.0,
		"direction": Vector2(1, 0),
		"damping_min": 2000.0,
		"damping_max": 3000.0,
		"z_index": 15
	},
	"knight_ult_beam_up": {
		"amount": 120,
		"lifetime": 0.8,
		"explosiveness": 0.95,
		"spread": 1.5,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 1500.0,
		"initial_velocity_max": 3500.0,
		"scale_amount_min": 8.0,
		"scale_amount_max": 20.0,
		"direction": Vector2(0, -1),
		"damping_min": 2000.0,
		"damping_max": 3000.0,
		"z_index": 15
	},
	"knight_ult_beam_down": {
		"amount": 120,
		"lifetime": 0.8,
		"explosiveness": 0.95,
		"spread": 1.5,
		"gravity": Vector2(0, 0),
		"initial_velocity_min": 1500.0,
		"initial_velocity_max": 3500.0,
		"scale_amount_min": 8.0,
		"scale_amount_max": 20.0,
		"direction": Vector2(0, 1),
		"damping_min": 2000.0,
		"damping_max": 3000.0,
		"z_index": 15
	}
}
