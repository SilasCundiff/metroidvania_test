extends BaseEnemy

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_timer: Timer = $JumpTimer

const jump_velocity: Vector2 = Vector2(100, -150)
const jump_wait_range: Vector2 = Vector2(2.5, 5)

var _jump: bool = false
var _seen_player: bool = false


func _ready() -> void:
	super._ready()
	start_timer()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if !is_on_floor():
		velocity.y += _gravity * delta
	else:
		velocity.x = 0
		animated_sprite_2d.play("idle")
	
	apply_jump()
	move_and_slide()
	flip_sprite()


func apply_jump() -> void:
	if !is_on_floor() or (!_seen_player or !_jump):
		return
	
	velocity = jump_velocity
	
	if !animated_sprite_2d.flip_h:
		velocity.x = velocity.x * -1
	
	_jump = false
	
	animated_sprite_2d.play("jump")
	start_timer()


func flip_sprite() -> void:
	if _player_ref.global_position.x > global_position.x and !animated_sprite_2d.flip_h:
		animated_sprite_2d.flip_h = true
	elif _player_ref.global_position.x < global_position.x and animated_sprite_2d.flip_h:
		animated_sprite_2d.flip_h = false


func start_timer() -> void:
	jump_timer.wait_time = randf_range(jump_wait_range.x, jump_wait_range.y)
	jump_timer.start()



func _on_jump_timer_timeout() -> void:
	_jump = true


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	_seen_player = true
