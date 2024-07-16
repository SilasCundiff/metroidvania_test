extends BaseEnemy

@onready var player_detector: RayCast2D = $PlayerDetector
@onready var ranged_attack: Node2D = $RangedAttack
@onready var attack_timer: Timer = $AttackTimer
@onready var line_to_player: Line2D = $Line2D


var _player_on_screen: bool = false
var _max_range: float = 200.0
var _can_attack: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_gravity = 0.0
	_player_ref = get_tree().get_nodes_in_group(GameManager.GROUP_PLAYER)[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	check_if_player_in_range()

func check_if_player_in_range() -> void:
	if _player_on_screen:
		var turret_position: Vector2 = global_position
		var player_position: Vector2 = _player_ref.global_position
		var distance_to_player: float = turret_position.distance_to(player_position)
		look_at(player_position)
		var color = Color(0, 1, 0)
		
		if distance_to_player <= _max_range:
			color = Color(1, 0, 0)
		elif distance_to_player >= _max_range: 
			color = Color(0, 1, 0)
		
		
		player_detector.look_at(player_position)
		player_detector.force_raycast_update()
		var collision_object = player_detector.get_collider()
		
		if player_detector.is_colliding() and _can_attack:
			start_attack_delay()
			ranged_attack.shoot(turret_position.direction_to(player_position), turret_position)
		
		draw_laser(player_position, color)
	elif !_player_on_screen:
		line_to_player.clear_points()



func draw_laser(player_position: Vector2, color: Color):
		# Convert global positions to local positions relative to the turret
		var local_turret_position: Vector2 = Vector2.ZERO
		var local_player_position: Vector2 = to_local(player_position)
		line_to_player.default_color = color
		# Update the Line2D points
		line_to_player.points = [local_turret_position, local_player_position]

func start_attack_delay() -> void:
	attack_timer.start()
	_can_attack = false


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	_player_on_screen = true


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	_player_on_screen = false


func _on_attack_timer_timeout() -> void:
	_can_attack = true
	pass # Replace with function body.
