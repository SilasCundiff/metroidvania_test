class_name AttackComponent
extends Node


@onready var ranged_attack: Node2D = $RangedAttack
#@onready var melee_attack: Node2D = $MeleeAttack
@export var melee_attack: Node2D

@onready var attack_timer: Timer = $AttackTimer



@export var attack_delay: float = 0.7
var player_current_direction: Vector2 = Vector2.RIGHT 
var player_current_position: Vector2 = Vector2(0.0, 0.0)
var attack_position: Vector2



func start_attack(attack_type: String) -> bool:
	#player_current_direction = current_direction	
	#attack_position = position
	attack_timer.start()
	
	match attack_type:
		"ranged":
			shoot()
	match attack_type:
		"melee":
			swing()
	
	return false

func update_position(player_direction: Vector2, player_position: Vector2) -> void:
	player_current_direction = player_direction
	player_current_position = player_position
	

func shoot() -> void:
	ranged_attack.shoot(player_current_direction, player_current_position)


func swing() -> void:
	melee_attack.swing()




func _on_attack_timer_timeout() -> void:
	SignalManager.on_attack_timer_finished.emit()
	pass
