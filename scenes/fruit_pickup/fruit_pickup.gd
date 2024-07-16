extends Area2D


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


const FRUIT: Array = ["melon", "kiwi", "banana", "cherries"]
const GRAVITY: float = 180.0
const JUMP: float = -80.0
const POINTS: int = 2

var _start_y: float
var _speed_y: float = JUMP
var _stopped: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_y = global_position.y
	animated_sprite_2d.play(FRUIT.pick_random())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _stopped:
		return
		
	
	position.y += _speed_y * delta
	_speed_y += GRAVITY * delta
	
	if global_position.y > _start_y:
		_stopped = true


func despawn_fruit() -> void:
	set_process(false)
	hide()
	queue_free()


func _on_lifetime_timeout() -> void:
	despawn_fruit()


func _on_area_entered(_area: Area2D) -> void:
	SignalManager.on_pickup_hit.emit(POINTS)
	despawn_fruit()

