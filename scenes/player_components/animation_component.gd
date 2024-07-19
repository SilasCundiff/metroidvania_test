class_name AnimationComponent
extends Node

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D


func handle_horizontal_flip(move_direction: Vector2, player_sprite: AnimatedSprite2D) -> void:
	if move_direction.x == 0:
		return
	player_sprite.flip_h = false if move_direction.x > 0 else true



func handle_move_animation(move_direction: Vector2, player: Player, player_sprite: AnimatedSprite2D) -> void:
	handle_horizontal_flip(move_direction, player_sprite)
	
	if move_direction.x != 0 and player._state == player.PLAYER_STATE.RUNNING and (player._state != player.PLAYER_STATE.MELEE_ATTACK or player._state != player.player.PLAYER_STATE.RANGED_ATTACK or player._state != player.PLAYER_STATE.DEFLECT_ATTACK):
		player_sprite.play("run")
	elif move_direction.x == 0 and player._state == player.PLAYER_STATE.IDLE and (player._state != player.PLAYER_STATE.MELEE_ATTACK or player._state != player.PLAYER_STATE.RANGED_ATTACK or player._state != player.PLAYER_STATE.DEFLECT_ATTACK):
		player_sprite.play("idle")


func handle_jump_animation(player: Player, player_sprite: AnimatedSprite2D) -> void:
	if player._state == player.PLAYER_STATE.JUMPING:
		player_sprite.play("jump")
	elif player._state == player.PLAYER_STATE.FALLING:
		player_sprite.play("fall")


func play_attack_animation(player_sprite: AnimatedSprite2D) -> void:
	player_sprite.play("attack")

func play_deflect_animation(player_sprite: AnimatedSprite2D) -> void:
	player_sprite.play("deflect")

func play_hurt_animation(player_sprite: AnimatedSprite2D, animation_player_invincible: AnimationPlayer) -> void:
	animation_player_invincible.play("invincible")
	player_sprite.play("hurt")

func play_kneel_animation(player_sprite: AnimatedSprite2D) -> void:
	player_sprite.play("kneel")
