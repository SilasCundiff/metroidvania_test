extends BaseEnemy

@onready var player_detector: RayCast2D = $PlayerDetector
@onready var direction_timer: Timer = $DirectionTimer
@onready var ranged_attack: Node2D = $RangedAttack
@onready var attack_timer: Timer = $AttackTimer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


const fly_speed: Vector2 = Vector2(35, 15)
var _fly_direction: Vector2 = Vector2.ZERO
var _can_attack: bool = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	velocity = _fly_direction
	
	move_and_slide()
	shoot()


func set_and_flip() -> void:
	var x_dir: float = sign(_player_ref.global_position.x - global_position.x)
	if x_dir > 0:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false	
	
	_fly_direction = Vector2(x_dir, 1) * fly_speed


func fly_to_player() -> void:
	set_and_flip()
	direction_timer.start()

func shoot() -> void:
	if player_detector.is_colliding() and _can_attack:
		start_attack_delay()
		ranged_attack.shoot(global_position.direction_to(_player_ref.global_position), global_position)

func start_attack_delay() -> void:
	attack_timer.start()
	_can_attack = false

func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	animated_sprite_2d.play("fly")
	fly_to_player()


func _on_direction_timer_timeout() -> void:
	fly_to_player()


func _on_attack_timer_timeout() -> void:
	_can_attack = true
	pass # Replace with function body.
