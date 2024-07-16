# PlayerData.gd
# This script acts as a singleton for storing player movement parameters

extends Node
class_name PlayerData

# Gravity parameters
var gravity_strength: float
var gravity_scale: float
var fall_gravity_mult: float
var max_fall_speed: float
var fast_fall_gravity_mult: float
var max_fast_fall_speed: float

# Run parameters
var run_max_speed: float
var run_acceleration: float
var run_accel_amount: float
var run_deceleration: float
var run_deccel_amount: float
var accel_in_air: float
var deccel_in_air: float
var do_conserve_momentum: bool = true

# Jump parameters
var jump_height: float
var jump_time_to_apex: float
var jump_force: float
var jump_cut_gravity_mult: float
var jump_hang_gravity_mult: float
var jump_hang_time_threshold: float
var jump_hang_acceleration_mult: float
var jump_hang_max_speed_mult: float

# Wall jump parameters
var wall_jump_force: Vector2
var wall_jump_run_lerp: float
var wall_jump_time: float
var do_turn_on_wall_jump: bool

# Slide parameters
var slide_speed: float
var slide_accel: float

# Assist parameters
var coyote_time: float
var jump_input_buffer_time: float

# Function to calculate derived parameters
func _ready():
	calculate_parameters()

# Function to calculate derived parameters
func calculate_parameters():
	gravity_strength = -(2 * jump_height) / (jump_time_to_apex * jump_time_to_apex)
	gravity_scale = gravity_strength / ProjectSettings.get_setting("physics/2d/default_gravity")
	run_accel_amount = (50 * run_acceleration) / run_max_speed
	run_deccel_amount = (50 * run_deceleration) / run_max_speed
	jump_force = abs(gravity_strength) * jump_time_to_apex
