extends Node
class_name InputComponent2D

# A simple class that get's the users input and returns either booleans for jumps or a Vector2 for the current input direction
# values for input direction can be (0, 0) to (1, 1) or (-1, -1). 
# values represent: (x, y)

var input_direction: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	update_input_direction()

func update_input_direction() -> void:
	input_direction.x = (int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))
	input_direction.y = (int(Input.is_action_pressed("up")) - int(Input.is_action_pressed("down")))


func get_input_direction() -> Vector2:
	return input_direction


func get_jump_input() -> bool:
	return Input.is_action_just_pressed("jump")


func get_jump_input_released() -> bool:
	return Input.is_action_just_released("jump")


