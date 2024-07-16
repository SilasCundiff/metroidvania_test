extends CharacterBody2D

class_name BaseEnemy


enum FACING {
	LEFT = -1,
	RIGHT = 1
}
const OFF_SCREEN_KILL_ME: float = 1000.0

@export var default_facing: FACING = FACING.LEFT
@export var points: int = 1
@warning_ignore("unused_private_class_variable")
@export var _speed: float = 30.0


@warning_ignore("unused_private_class_variable")
var _gravity: float = 800.0
@warning_ignore("unused_private_class_variable")
var _facing: FACING = default_facing
var _player_ref: Player
var _dying: bool = false


func _ready() -> void:
	_player_ref = get_tree().get_nodes_in_group(GameManager.GROUP_PLAYER)[0]


func _physics_process(_delta: float) -> void:
	pass

func fallen_off() -> void:
	if global_position.y > OFF_SCREEN_KILL_ME:
		queue_free()


func die() -> void:
	if _dying:
		return
	
	_dying = true
	SignalManager.on_enemy_hit.emit(points, global_position)
	ObjectMaker.create_object(global_position, ObjectMaker.SCENE_KEY.EXPLOSION)
	ObjectMaker.create_object(global_position, ObjectMaker.SCENE_KEY.PICKUP)
	set_physics_process(false)
	hide()
	queue_free()


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	pass # Replace with function body.


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	pass # Replace with function body.


func _on_hit_box_area_entered(_area: Area2D) -> void:
	die()
	pass # Replace with function body.
