extends CharacterBody2D

@export var SPEED : float = 300.0 # Base horizontal movement speed
@export var GROUND_ACCELERATION : float = 1200.0 # Acceleration on the ground
@export var AIR_ACCELERATION : float = 600.0 # Base acceleration in the air
@export var FRICTION : float = 1400.0 # Base friction
@export var GRAVITY : float = 1800.0 # Gravity when moving upwards
@export var FALL_GRAVITY : float = 2500.0 # Gravity when falling downwards
@export var WALL_GRAVITY : float = 25.0 # Gravity while sliding on a wall
@export var JUMP_VELOCITY : float = -500.0 # Maximum jump strength
@export var WALL_JUMP_VELOCITY : float = -500.0 # Maximum wall jump strength
@export var WALL_JUMP_PUSHBACK : float = 200.0 # Horizontal push strength off walls
@export var INPUT_BUFFER_PATIENCE : float = 0.1 # Input queue patience time
@export var COYOTE_TIME : float = 0.08 # Coyote patience time
@export var FLOOR_DAMPING_ON_FLOOR : float = 1.0 # Damping factor when on the floor
@export var FLOOR_DAMPING_IN_AIR : float = 0.2 # Damping factor when in the air
@export var SPRINT_MULTIPLIER : float = 2.0 # Speed multiplier while sprinting
@export var START_JUMP_CHARGES : int = 2 # Initial number of jump charges
@export var MAX_JUMP_CHARGES : int = 3 # Maximum number of jump charges
@export var DASH_SPEED : float = 600.0 # Speed of the dash
@export var DASH_TIME : float = 0.2 # Duration of the dash
@export var UPWARD_DIAGONAL_MULTIPLIER : float = 1.5 # Multiplier for upward diagonal dash length
@export var DOWNWARD_DASH_MULTIPLIER : float = 2.0 # Multiplier for downward dash speed
@export var DOUBLE_TAP_TIME : float = 0.2 # Time window for double-tap detection
@export var DASH_COOLDOWN : float = 2.0 # Cooldown time for dash

var JUMP_CHARGES : int # Current number of jump charges
var input_buffer : Timer # Reference to the input queue timer
var coyote_timer : Timer # Reference to the coyote timer
var coyote_jump_available : bool = true
var dash_timer : Timer # Timer for the dash duration
var dash_cooldown_timer : Timer # Timer for the dash cooldown
var double_tap_timer : Timer # Timer for detecting double taps
var dashing : bool = false # Whether the player is currently dashing
var dash_direction : Vector2 = Vector2.ZERO # Direction of the dash
var current_direction : Vector2 = Vector2(1, 0) # Default direction is right
var last_tap_direction : int = 0 # Last tapped direction for double-tap detection
var can_dash : bool = true # Whether the player can dash
var on_wall : bool = false # Whether the player is on the wall
var just_wall_jumped : bool = false # Whether the player just jumped off a wall

func _ready() -> void:
	# Initialize jump charges
	reset_jump_charges()

	# Set up input buffer timer
	input_buffer = Timer.new()
	input_buffer.wait_time = INPUT_BUFFER_PATIENCE
	input_buffer.one_shot = true
	add_child(input_buffer)

	# Set up coyote timer
	coyote_timer = Timer.new()
	coyote_timer.wait_time = COYOTE_TIME
	coyote_timer.one_shot = true
	add_child(coyote_timer)
	coyote_timer.timeout.connect(Callable(self, "coyote_timeout"))

	# Set up dash timer
	dash_timer = Timer.new()
	dash_timer.wait_time = DASH_TIME
	dash_timer.one_shot = true
	dash_timer.connect("timeout", Callable(self, "end_dash"))
	add_child(dash_timer)

	# Set up dash cooldown timer
	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.wait_time = DASH_COOLDOWN
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.connect("timeout", Callable(self, "reset_dash_cooldown"))
	add_child(dash_cooldown_timer)

	# Set up double-tap detection timer
	double_tap_timer = Timer.new()
	double_tap_timer.wait_time = DOUBLE_TAP_TIME
	double_tap_timer.one_shot = true
	add_child(double_tap_timer)

func _physics_process(delta : float) -> void:
	# Update the current direction
	update_current_direction()
	
	# Handle dash input
	handle_dash_input()
	handle_movement_input(delta)
	# Apply velocity
	move_and_slide()

func handle_movement_input(delta: float) -> void:
		# Get inputs
	var horizontal_input : float = Input.get_axis("left", "right")
	var jump_attempted : bool = Input.is_action_just_pressed("jump")
	
	# Add the gravity and handle jumping
	if jump_attempted or input_buffer.time_left > 0:
		if coyote_jump_available and JUMP_CHARGES > 0: # If jumping on the ground
			velocity.y = JUMP_VELOCITY
			coyote_jump_available = false
			use_jump_charge(1)
			just_wall_jumped = false
		elif is_on_wall() and horizontal_input != 0 and JUMP_CHARGES > 0: # If jumping off a wall
			velocity.y = WALL_JUMP_VELOCITY
			velocity.x = WALL_JUMP_PUSHBACK * -sign(horizontal_input)
			use_jump_charge(1)
			just_wall_jumped = true
		elif JUMP_CHARGES > 0: # If jumping in the air and has jump charges
			velocity.y = JUMP_VELOCITY
			use_jump_charge(1)
			just_wall_jumped = false
		elif jump_attempted: # Queue input buffer if jump was attempted
			input_buffer.start()
	
	# Shorten jump if jump key is released
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = JUMP_VELOCITY / 4
	
	# Apply gravity and reset coyote jump
	if is_on_floor():
		coyote_jump_available = true
		coyote_timer.stop()
		reset_jump_charges()
		on_wall = false
		just_wall_jumped = false
	elif is_on_wall():
		reset_jump_charges()
		if not on_wall:
			on_wall = true
			velocity.y = 0 # Reset vertical velocity when first touching the wall
		velocity.y += WALL_GRAVITY * delta # Apply wall gravity for sliding down
	
	if not is_on_floor() and not is_on_wall():
		on_wall = false
		if coyote_jump_available:
			if coyote_timer.is_stopped():
				coyote_timer.start()
		velocity.y += get_gravity(horizontal_input) * delta
	
	# Handle horizontal motion and friction if not dashing
	if not dashing:
		var floor_damping : float = FLOOR_DAMPING_ON_FLOOR if is_on_floor() else FLOOR_DAMPING_IN_AIR
		var sprint_multiplier : float = 1.0
		if Input.is_action_pressed("sprint"):
			sprint_multiplier = SPRINT_MULTIPLIER
		var current_acceleration : float = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
		if just_wall_jumped and not is_on_floor():
			current_acceleration *= 2.0 # Double air acceleration if just wall jumped
		if horizontal_input != 0:
			velocity.x = move_toward(velocity.x, horizontal_input * SPEED * sprint_multiplier, current_acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, (FRICTION * delta) * floor_damping)


## Returns the gravity based on the state of the player
func get_gravity(input_dir : float = 0) -> float:
	return GRAVITY if velocity.y < 0 else FALL_GRAVITY

## Reset coyote jump
func coyote_timeout() -> void:
	coyote_jump_available = false

## Adds jump charges up to the maximum limit
func add_jump_charge(num_charges : int) -> void:
	if JUMP_CHARGES < MAX_JUMP_CHARGES:
		JUMP_CHARGES += num_charges

## Uses jump charges if available
func use_jump_charge(num_charges : int) -> void:
	if JUMP_CHARGES >= 1:
		JUMP_CHARGES -= num_charges

## Resets jump charges to the initial value
func reset_jump_charges() -> void:
	JUMP_CHARGES = START_JUMP_CHARGES

## Updates the current input direction
func update_current_direction() -> void:
	current_direction = Vector2.ZERO
	if Input.is_action_pressed("right"):
		current_direction.x += 1
	if Input.is_action_pressed("left"):
		current_direction.x -= 1
	if Input.is_action_pressed("up"):
		current_direction.y -= 1
	if Input.is_action_pressed("down"):
		current_direction.y += 1
	if current_direction == Vector2.ZERO:
		current_direction = Vector2(1, 0) # Default to right

## Handles input for dashing
func handle_dash_input() -> void:
	if can_dash and Input.is_action_just_pressed("dash"):
		# Do not allow dashing downward if on the floor
		if is_on_floor() and current_direction.y > 0:
			return
		start_dash(current_direction)
	# Double-tap detection for left, right, and down
	if Input.is_action_just_pressed("right"):
		handle_double_tap(1, Vector2(1, 0))
	elif Input.is_action_just_pressed("left"):
		handle_double_tap(-1, Vector2(-1, 0))
	elif Input.is_action_just_pressed("down") or (Input.is_action_pressed("jump") and Input.is_action_just_pressed("down")):
		handle_double_tap(2, Vector2(0, 1))

## Handles double-tap input for dashing
func handle_double_tap(tap_direction : int, dash_vector : Vector2) -> void:
	if can_dash and last_tap_direction == tap_direction and not double_tap_timer.is_stopped():
		start_dash(dash_vector)
	else:
		double_tap_timer.start()
	last_tap_direction = tap_direction

## Starts the dash in the given direction
func start_dash(direction : Vector2) -> void:
	dashing = true
	dash_direction = direction.normalized()
	var final_dash_speed := DASH_SPEED

	# Double the length of upward diagonal dashes
	if dash_direction.y < 0 and dash_direction.x != 0:
		final_dash_speed *= UPWARD_DIAGONAL_MULTIPLIER
	
	# Increase speed for downward dashes
	if dash_direction.y > 0:
		final_dash_speed *= DOWNWARD_DASH_MULTIPLIER

	velocity = dash_direction * final_dash_speed
	dash_timer.start()
	can_dash = false
	dash_cooldown_timer.start()

	# Consume a jump charge if dashing upwards
	if direction.y < 0:
		use_jump_charge(1)

## Ends the dash
func end_dash() -> void:
	dashing = false
	dash_direction = Vector2.ZERO

## Resets the dash cooldown
func reset_dash_cooldown() -> void:
	can_dash = true
