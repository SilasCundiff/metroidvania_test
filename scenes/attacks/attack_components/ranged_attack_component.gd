#named "Shooter" in the course
# not to be confused with "player_ranged_attack"
# this component is purely responsible for providing the functionality to *create* a "player_ranged_attack" to the player.
# for the attacks actual properties, see "scenes/attacks/player/player_ranged_attack"
extends Node2D


@export var speed: float = 400.0
@export var life_span: float = 3.0
@export var attack_key: ObjectMaker.ATTACK_KEY


var _direction: Vector2 = Vector2.RIGHT


func shoot(direction: Vector2, pos: Vector2) -> void:
	_direction = direction
	ObjectMaker.create_attack(direction, life_span, speed, pos, attack_key)

