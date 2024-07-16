extends Node


enum ATTACK_KEY {
	ENEMY_RANGED,
	PLAYER_RANGED,
	PLAYER_MELEE
}
enum SCENE_KEY {
	EXPLOSION, PICKUP
}

const SIMPLE_SCENES: Dictionary = {
	SCENE_KEY.EXPLOSION: preload("res://scenes/enemy_explosion/enemy_explosion.tscn"),
	SCENE_KEY.PICKUP: preload("res://scenes/fruit_pickup/fruit_pickup.tscn")
}

const attacks: Dictionary = {
	ATTACK_KEY.ENEMY_RANGED: preload("res://scenes/attacks/enemy/enemy_ranged_attack.tscn"),
	ATTACK_KEY.PLAYER_RANGED: preload("res://scenes/attacks/player/player_ranged_attack.tscn"),
	ATTACK_KEY.PLAYER_MELEE: preload("res://scenes/attacks/player/player_melee_attack.tscn")
}

func add_child_deferred(child_to_add: Node) -> void:
	get_tree().root.add_child(child_to_add)


func call_add_child(child_to_add: Node) -> void:
	call_deferred("add_child_deferred", child_to_add)


func create_attack(direction: Vector2, life_span: float, speed: float, start_pos: Vector2, key: ATTACK_KEY) -> void:
	var new_a: Node = attacks[key].instantiate()
	new_a.setup(direction, life_span, speed)
	new_a.global_position = start_pos
	
	call_add_child(new_a)


func create_object(start_pos: Vector2, key: SCENE_KEY) -> void:
	var new_exp: Node = SIMPLE_SCENES[key].instantiate()
	new_exp.global_position = start_pos
	call_add_child(new_exp)


















