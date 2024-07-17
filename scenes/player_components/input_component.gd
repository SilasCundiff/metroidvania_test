class_name InputComponent
extends Node


var input_direction: Vector2 = Vector2.ZERO
var _disable_input: bool = false
var _disable_movement: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_input_direction()


func update_input_direction():
	input_direction.x = (int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))
	input_direction.y = (int(Input.is_action_pressed("up")) - int(Input.is_action_pressed("down")))

func set_disable_input(input_disabled: bool) -> void:
	_disable_input = input_disabled

func set_disable_movement(input_disabled: bool) -> void:
	_disable_movement = input_disabled

func get_input_direction() -> Vector2:
	if _disable_movement:
		input_direction.x = 0
		return input_direction
	return input_direction

func get_jump_input() -> bool:
	if _disable_input:
		return false
	return Input.is_action_just_pressed("jump")

func get_jump_input_released() -> bool:
	if _disable_input:
		return false
	return Input.is_action_just_released("jump")
#
func get_ranged_attack_input() -> bool:
	if _disable_input:
		return false
	return Input.is_action_just_pressed("ranged_attack")

func get_melee_attack_input() -> bool:
	if _disable_input:
		return false
	return Input.is_action_just_pressed("melee_attack") and !Input.is_key_pressed(KEY_SHIFT)

func get_deflect_attack_input() -> bool:
	if _disable_input:
		return false
	return Input.is_action_just_pressed("deflect_attack")



