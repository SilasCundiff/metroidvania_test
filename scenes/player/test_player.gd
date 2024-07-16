extends CharacterBody2D

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

# Components and state variables
var is_facing_right: bool = true
var is_jumping: bool = false
var is_wall_jumping: bool = false
var is_sliding: bool = false
var last_on_ground_time: float = 0
var last_on_wall_time: float = 0
var last_on_wall_right_time: float = 0
var last_on_wall_left_time: float = 0
var is_jump_cut: bool = false
var is_jump_falling: bool = false
var wall_jump_start_time: float = 0
var last_wall_jump_dir: int = 0
var move_input: Vector2 = Vector2.ZERO
var last_pressed_jump_time: float = 0

# Ground and wall check parameters
@export var ground_check_position: Vector2
@export var ground_check_size: Vector2 = Vector2(0.49, 0.03)
@export var front_wall_check_position: Vector2
@export var back_wall_check_position: Vector2
@export var wall_check_size: Vector2 = Vector2(0.5, 1.0)
@export var ground_layer: int

# Function to calculate derived parameters
func calculate_parameters():
	# Calculate gravity strength using the formula (gravity = 2 * jumpHeight / timeToJumpApex^2)
	gravity_strength = -(2 * jump_height) / (jump_time_to_apex * jump_time_to_apex)
	# Calculate the rigidbody's gravity scale (relative to default gravity value in project settings)
	gravity_scale = gravity_strength / ProjectSettings.get_setting("physics/2d/default_gravity")
	# Calculate run acceleration and deceleration amounts
	run_accel_amount = (50 * run_acceleration) / run_max_speed
	run_deccel_amount = (50 * run_deceleration) / run_max_speed
	# Calculate jump force using the formula (initialJumpVelocity = gravity * timeToJumpApex)
	jump_force = abs(gravity_strength) * jump_time_to_apex

func _ready():
	# Calculate and set derived parameters
	calculate_parameters()
	# Set initial gravity scale
	set_gravity_scale(gravity_scale)

func _process(delta):
	# Update timers
	last_on_ground_time -= delta
	last_on_wall_time -= delta
	last_on_wall_right_time -= delta
	last_on_wall_left_time -= delta
	last_pressed_jump_time -= delta

	# Handle input
	move_input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if move_input.x != 0:
		check_direction_to_face(move_input.x > 0)

	if Input.is_action_just_pressed("jump"):
		on_jump_input()

	if Input.is_action_just_released("jump"):
		on_jump_up_input()

	# Perform collision checks
	perform_collision_checks()

	# Perform jump checks
	perform_jump_checks()

	# Perform slide checks
	perform_slide_checks()

	# Handle gravity
	handle_gravity()

func _physics_process(delta):
	# Handle running and sliding
	if is_wall_jumping:
		run(wall_jump_run_lerp)
	else:
		run(1.0)

	if is_sliding:
		slide()

# Perform collision checks to update the timers for ground and wall contact
func perform_collision_checks():
	# Ground check
	if not is_jumping:
		if is_on_floor():
			last_on_ground_time = coyote_time

	# Wall checks
	if not is_wall_jumping:
		if is_on_wall():
			last_on_wall_time = coyote_time
			if move_input.x > 0:
				last_on_wall_right_time = coyote_time
			elif move_input.x < 0:
				last_on_wall_left_time = coyote_time

# Perform jump checks to manage jumping state
func perform_jump_checks():
	if is_jumping and velocity.y < 0:
		is_jumping = false
		if not is_wall_jumping:
			is_jump_falling = true

	if is_wall_jumping and (get_process_delta_time() - wall_jump_start_time > wall_jump_time):
		is_wall_jumping = false

	if last_on_ground_time > 0 and not is_jumping and not is_wall_jumping:
		is_jump_cut = false
		is_jump_falling = false

	if can_jump() and last_pressed_jump_time > 0:
		is_jumping = true
		is_wall_jumping = false
		is_jump_cut = false
		is_jump_falling = false
		jump()
	elif can_wall_jump() and last_pressed_jump_time > 0:
		is_wall_jumping = true
		is_jumping = false
		is_jump_cut = false
		is_jump_falling = false
		wall_jump_start_time = get_process_delta_time()
		last_wall_jump_dir = -1 if last_on_wall_right_time > 0 else 1
		wall_jump(last_wall_jump_dir)

# Perform slide checks to manage sliding state
func perform_slide_checks():
	is_sliding = can_slide() and ((last_on_wall_left_time > 0 and move_input.x < 0) or (last_on_wall_right_time > 0 and move_input.x > 0))

# Handle gravity adjustments based on player state
func handle_gravity():
	if is_sliding:
		set_gravity_scale(0)
	elif velocity.y < 0 and move_input.y < 0:
		set_gravity_scale(gravity_scale * fast_fall_gravity_mult)
		velocity.y = max(velocity.y, -max_fast_fall_speed)
	elif is_jump_cut:
		set_gravity_scale(gravity_scale * jump_cut_gravity_mult)
		velocity.y = max(velocity.y, -max_fall_speed)
	elif (is_jumping or is_wall_jumping or is_jump_falling) and abs(velocity.y) < jump_hang_time_threshold:
		set_gravity_scale(gravity_scale * jump_hang_gravity_mult)
	else:
		set_gravity_scale(gravity_scale * fall_gravity_mult if velocity.y < 0 else gravity_scale)

# Handle jump input
func on_jump_input():
	last_pressed_jump_time = jump_input_buffer_time

# Handle jump release input
func on_jump_up_input():
	if can_jump_cut() or can_wall_jump_cut():
		is_jump_cut = true

# Set gravity scale for the player
func set_gravity_scale(scale: float):
	gravity_scale = scale

# Check and update the direction the player is facing
func check_direction_to_face(is_moving_right: bool):
	if is_moving_right != is_facing_right:
		turn()

# Check if the player can jump
func can_jump() -> bool:
	return last_on_ground_time > 0 and not is_jumping

# Check if the player can perform a wall jump
func can_wall_jump() -> bool:
	return last_pressed_jump_time > 0 and last_on_wall_time > 0 and last_on_ground_time <= 0 and (not is_wall_jumping or (last_on_wall_right_time > 0 and last_wall_jump_dir == 1) or (last_on_wall_left_time > 0 and last_wall_jump_dir == -1))

# Check if the player can cut the jump short
func can_jump_cut() -> bool:
	return is_jumping and velocity.y > 0

# Check if the player can cut the wall jump short
func can_wall_jump_cut() -> bool:
	return is_wall_jumping and velocity.y > 0

# Check if the player can slide
func can_slide() -> bool:
	return last_on_wall_time > 0 and not is_jumping and not is_wall_jumping and last_on_ground_time <= 0

# Handle player running
func run(lerp_amount: float):
	var target_speed = move_input.x * run_max_speed
	target_speed = lerp(velocity.x, target_speed, lerp_amount)

	var accel_rate: float
	if last_on_ground_time > 0:
		accel_rate = run_accel_amount if abs(target_speed) > 0.01 else run_deccel_amount
	else:
		accel_rate = run_accel_amount * accel_in_air if abs(target_speed) > 0.01 else run_deccel_amount * deccel_in_air

	if (is_jumping or is_wall_jumping or is_jump_falling) and abs(velocity.y) < jump_hang_time_threshold:
		accel_rate *= jump_hang_acceleration_mult
		target_speed *= jump_hang_max_speed_mult

	if do_conserve_momentum and abs(velocity.x) > abs(target_speed) and sign(velocity.x) == sign(target_speed) and abs(target_speed) > 0.01 and last_on_ground_time < 0:
		accel_rate = 0

	var speed_diff = target_speed - velocity.x
	var movement = speed_diff * accel_rate
	velocity.x += movement

# Turn the player to face the opposite direction
func turn():
	var scale = self.scale
	scale.x *= -1
	self.scale = scale
	is_facing_right = not is_facing_right

# Perform a jump
func jump():
	last_pressed_jump_time = 0
	last_on_ground_time = 0
	var force = jump_force
	if velocity.y < 0:
		force -= velocity.y
	velocity.y = -force

# Perform a wall jump
func wall_jump(dir: int):
	last_pressed_jump_time = 0
	last_on_ground_time = 0
	last_on_wall_right_time = 0
	last_on_wall_left_time = 0
	var force = wall_jump_force
	force.x *= dir
	if sign(velocity.x) != sign(force.x):
		force.x -= velocity.x
	if velocity.y < 0:
		force.y -= velocity.y
	velocity = force

# Handle player sliding
func slide():
	var speed_diff = slide_speed - velocity.y
	var movement = speed_diff * slide_accel
	var physics_iterations_per_second = ProjectSettings.get_setting("physics/common/physics_fps")
	movement = clamp(movement, -abs(speed_diff) / physics_iterations_per_second, abs(speed_diff) / physics_iterations_per_second)
	velocity.y += movement


# Drawing collision check boxes in the editor
func _draw():
	draw_rect(Rect2(ground_check_position - ground_check_size / 2, ground_check_size), Color(0, 1, 0))
	draw_rect(Rect2(front_wall_check_position - wall_check_size / 2, wall_check_size), Color(0, 0, 1))
	draw_rect(Rect2(back_wall_check_position - wall_check_size / 2, wall_check_size), Color(0, 0, 1))
