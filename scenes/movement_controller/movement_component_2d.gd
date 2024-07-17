class_name MovementComponent2D
extends Node

@export_subgroup("Settings")
@export var max_speed: float = 350.0
@export var ground_acceleration: float = 15.0
@export var air_acceleration: float = 5.0
@export var ground_friction: float = 60.0
@export var air_friction: float = 5.0
@export var stop_threshold: float = 0.005 # Threshold for stopping the player

var velocity: Vector2 = Vector2.ZERO


# Handle horizontal movement
func handle_horizontal_movement(body: CharacterBody2D, direction: Vector2, delta: float) -> void:
	var current_acceleration: float
	var current_friction: float

	if body.is_on_floor():
		current_acceleration = ground_acceleration
		current_friction = ground_friction
	else:
		current_acceleration = air_acceleration
		current_friction = air_friction

	if direction.x != 0:
		velocity.x = lerp(velocity.x, float(direction.x) * max_speed, current_acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, current_friction * delta)

	# Clamp velocity to zero if it's below the stop threshold
	if abs(velocity.x) < stop_threshold:
		velocity.x = 0.0

	body.velocity.x = velocity.x

