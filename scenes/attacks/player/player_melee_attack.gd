extends Area2D

@onready var attack_hitbox: CollisionShape2D = $AttackHitbox
@onready var swing_timer: Timer = $SwingTimer

var swing_in_progress: bool = false


	#position.x += x_direction * 5
func swing() -> void:
	swing_timer.start()
	set_collision_layer_value(4, true)


func _on_swing_timer_timeout() -> void:
	swing_in_progress = false
	set_collision_layer_value(4, false)
