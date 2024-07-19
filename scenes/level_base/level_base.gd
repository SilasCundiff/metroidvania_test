extends Node2D


@onready var player_cam: Camera2D = $PlayerCam
@onready var player: CharacterBody2D = $Player
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D
var player_horizontal_direction_offset: float = 0
var player_vertical_direction_offset: float = 0
var player_vertical_follow_damp_max: float = 0.75
var player_vertical_follow_damp_min: float = 0.15

func _physics_process(_delta: float) -> void:
	#print(player.velocity)
	player_horizontal_direction_offset = player.velocity.x
	if player.velocity.y < 0:
		player_vertical_direction_offset = lerp(player_vertical_direction_offset, player.velocity.y, 0.95)
		#player_vertical_direction_offset = clampf(lerp(player_vertical_direction_offset, player.velocity.y, 0.25), -450.0, 400.0)
		phantom_camera_2d.follow_damping_value.y = 0.75
	elif player.velocity.y >= 0 and player.velocity.y <= 400:
			player_vertical_direction_offset =  50.0
			phantom_camera_2d.follow_damping_value.y = 0.75
	elif player.velocity.y > 400:
			player_vertical_direction_offset = clampf(lerp(player_vertical_direction_offset, player.velocity.y, 0.55), -450.0, 400.0)
			#player_vertical_direction_offset = clampf(lerp(player_vertical_direction_offset, player.velocity.y, 0.25), 0.0, 450.0)
			phantom_camera_2d.follow_damping_value.y = .25

	#print(player_vertical_direction_offset," ", phantom_camera_2d.follow_damping_value.y)
	#player_cam.position = player.position
	#phantom_camera_2d.set_follow_target(player)
	#print(player.velocity.y)
	#
	#if player.get_current_direction().x == 1:
		#player_horizontal_direction_offset = 100
	#elif player.get_current_direction().x == -1:
		#player_horizontal_direction_offset = -100
	
	#if player.get_current_direction().y == 1:
		#player_vertical_direction_offset = -100
	#elif player.get_current_direction().y == -1:
		#player_vertical_direction_offset = -100
	
	
	phantom_camera_2d.set_follow_offset(Vector2(player_horizontal_direction_offset, player_vertical_direction_offset))
	pass
