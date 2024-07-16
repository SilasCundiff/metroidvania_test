extends Node


signal on_enemy_hit(points: int, enemy_position: Vector2)
signal on_pickup_hit(points: int)
signal on_attack_timer_finished
signal on_invincible(invincible_status: bool)
signal on_hurt(hurt_status: bool)
