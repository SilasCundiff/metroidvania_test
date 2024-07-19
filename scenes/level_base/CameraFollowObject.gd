extends Node2D

@onready var player: Player = $"../Player"
var _is_facing_right: bool = true;

func _ready() -> void:
	print(player.get_current_direction())
	pass


func _process(delta: float) -> void:
	global_position = player.global_position
	
#
#func determine_rotation() -> float:
	#pass
