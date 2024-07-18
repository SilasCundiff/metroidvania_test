extends Node2D


@onready var player_cam: Camera2D = $PlayerCam
@onready var player: CharacterBody2D = $Player
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D


func _physics_process(_delta: float) -> void:
	#player_cam.position = player.position
	#phantom_camera_2d.set_follow_target(player)
	print()
	if player.get_current_direction().x == 1:
		phantom_camera_2d.set_follow_offset(Vector2(100, 300))
	else:
		phantom_camera_2d.set_follow_offset(Vector2(-100, 100))
	pass
