extends Area2D


@onready var hurt_timer: Timer = $HurtTimer
@onready var invincible_timer: Timer = $InvincibleTimer



var hurt_jump_velocity: Vector2 = Vector2(0, -150.0)
var _invincible: bool = false
var _hurt: bool = false



func get_hurt_jump_velocity() -> Vector2:
	return hurt_jump_velocity


func apply_hit() -> void:
	if _invincible:
		return
		
	_hurt = true
	SignalManager.on_hurt.emit(_hurt)
	hurt_timer.start()
	go_invincible()


func go_invincible() -> void:
	_invincible = true
	SignalManager.on_invincible.emit(_invincible)
	invincible_timer.start()


func _on_invincible_timer_timeout() -> void:
	_invincible = false
	SignalManager.on_invincible.emit(_invincible)



func _on_hurt_timer_timeout() -> void:
	_hurt = false
	SignalManager.on_hurt.emit(_hurt)



func _on_area_entered(_area: Area2D) -> void:
	apply_hit()


