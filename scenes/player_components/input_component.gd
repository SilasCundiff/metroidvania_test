class_name InputComponent
extends Node

var input_horitontal: float = 0.0
var _disable_input: bool = false
var _disable_movement: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	input_horitontal = Input.get_axis("left", "right")


func set_disable_input(input_disabled: bool) -> void:
	_disable_input = input_disabled

func set_disable_movement(input_disabled: bool) -> void:
	_disable_movement = input_disabled

func get_input_horizontal() -> float:
	if _disable_movement:
		input_horitontal = 0.0
		return input_horitontal
	return input_horitontal

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


func get_kneel_input() -> bool:
	if _disable_input:
		return false
	return Input.is_action_pressed("kneel")



