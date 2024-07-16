extends Node2D


@onready var player_cam: Camera2D = $PlayerCam
@onready var player: CharacterBody2D = $Player


func _physics_process(_delta: float) -> void:
	player_cam.position = player.position
