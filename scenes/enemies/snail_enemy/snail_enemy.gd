extends BaseEnemy


@onready var floor_detection: RayCast2D = $FloorDetection
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if not is_on_floor():
		velocity.y += _gravity * delta
	else:
		velocity.x = _speed * _facing
		
	move_and_slide()
	
	if (is_on_wall() or not floor_detection.is_colliding()) and is_on_floor():
		flip_sprite()

func flip_sprite() -> void:
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
	floor_detection.position.x = floor_detection.position.x * -1
	
	if _facing == FACING.LEFT:
		_facing = FACING.RIGHT
	else:
		_facing = FACING.LEFT

