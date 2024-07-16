extends Area2D

@onready var attack_sprite: AnimatedSprite2D = $AttackSprite

var _direction: Vector2 = Vector2.RIGHT
var _life_span: float = 20.0
var _life_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var x_direction: float = _direction.x
	if x_direction == 400:
		attack_sprite.flip_h = false
	elif x_direction == -400:
		attack_sprite.flip_h = true
	attack_sprite.play("Attack")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	check_expired(delta)
	position += _direction * delta


func _on_area_entered(_area: Area2D) -> void:
	queue_free()


func check_expired(delta: float) -> void:
	_life_time += delta
	if _life_time > _life_span:
		queue_free()


func setup(dir: Vector2, life_span: float, speed: float) -> void:
	_direction = dir.normalized() * speed
	_life_span = life_span
