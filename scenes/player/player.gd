extends CharacterBody2D

class_name Player

enum PLAYER_STATE {
	IDLE,
	RUNNING,
	JUMPING,
	FALLING,
	HURT,
	DEAD,
	RANGED_ATTACK,
	MELEE_ATTACK,
	DEFLECT_ATTACK,
	KNEELING
}

@onready var gravity_component: GravityComponent = $GravityComponent
@onready var advanced_jump_component: AdvancedJumpComponent = $AdvancedJumpComponent
@onready var attack_component: AttackComponent = $AttackComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var animation_component: AnimationComponent = $AnimationComponent
@onready var player_hitbox_component: Area2D = $PlayerHitboxComponent


@onready var debug_label: Label = $DebugLabel
@onready var sound_player: AudioStreamPlayer2D = $SoundPlayer
@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player_invincible: AnimationPlayer = $AnimationPlayerInvincible
@onready var input_component: InputComponent = $InputComponent
@onready var player_melee_attack: Area2D = $PlayerMeleeAttack



var _state: PLAYER_STATE = PLAYER_STATE.IDLE
var first_load: bool = true
var _movement_disabled: bool = false

func _ready() -> void:
	SignalManager.on_attack_timer_finished.connect(on_attack_timer_finished)
	SignalManager.on_invincible.connect(on_invincible)
	SignalManager.on_hurt.connect(on_hurt)


func _physics_process(delta: float) -> void:
	gravity_component.handle_gravity(self, delta)
	movement_component.handle_horizontal_movement(self, input_component.get_input_horizontal())
	advanced_jump_component.handle_jump(self, input_component.get_jump_input(), input_component.get_jump_input_released())
	animation_component.handle_move_animation(input_component.get_input_horizontal(), self, player_sprite)
	animation_component.handle_jump_animation(self, player_sprite)
	
	handle_perform_attack()
	handle_kneeling_action()
	
	attack_component.update_position(get_current_direction(), global_position)
	updateMeleeHitbox()
	
	update_debug_level()
	calculate_states()
	move_and_slide()


func update_debug_level() -> void:
	debug_label.text = "On Floor: %s\nOn Wall: %s\nState: %s\nVelocity: %.2f, %.2f" % [
		is_on_floor(),
		is_on_wall(),
		PLAYER_STATE.keys()[_state],
		velocity.x, velocity.y
	]


# states
func calculate_states()  -> void:
	if _state == PLAYER_STATE.HURT or _state == PLAYER_STATE.RANGED_ATTACK or _state == PLAYER_STATE.MELEE_ATTACK or _state == PLAYER_STATE.DEFLECT_ATTACK or _movement_disabled:
		return
	
	if is_on_floor():
		if velocity.x == 0:
			set_state(PLAYER_STATE.IDLE)
		else:
			set_state(PLAYER_STATE.RUNNING)
	else:	
		if velocity.y > 0:
			set_state(PLAYER_STATE.FALLING)
		else:
			set_state(PLAYER_STATE.JUMPING)

# set state and handle audio/animations
func set_state(new_state: PLAYER_STATE)  -> void:
	if new_state == _state:
		return
	
	if _state == PLAYER_STATE.FALLING:
		if new_state == PLAYER_STATE.IDLE or new_state == PLAYER_STATE.RUNNING:
			if first_load:
				first_load = false
			elif !first_load:
				SoundManager.play_clip(sound_player, SoundManager.SOUND_LAND)
	
	_state = new_state
	
	match _state:
		PLAYER_STATE.IDLE:
			input_component.set_disable_input(false)
			input_component.set_disable_movement(false)
			pass
		PLAYER_STATE.RUNNING:
			input_component.set_disable_input(false)
			pass
		PLAYER_STATE.JUMPING:
			SoundManager.play_clip(sound_player, SoundManager.SOUND_JUMP)
			input_component.set_disable_input(false)
			pass
		PLAYER_STATE.FALLING:
			input_component.set_disable_input(false)
			pass
		PLAYER_STATE.HURT:
			input_component.set_disable_input(true)
			SoundManager.play_clip(sound_player, SoundManager.SOUND_DAMAGE)
			pass
		PLAYER_STATE.DEAD:
			input_component.set_disable_input(true)
			pass
		PLAYER_STATE.RANGED_ATTACK:
			input_component.set_disable_input(true)
			input_component.set_disable_movement(true)
			SoundManager.play_clip(sound_player, SoundManager.SOUND_LASER)
			animation_component.play_attack_animation(player_sprite)
			pass
		PLAYER_STATE.MELEE_ATTACK:
			input_component.set_disable_input(true)
			input_component.set_disable_movement(true)
			SoundManager.play_clip(sound_player, SoundManager.SOUND_CHECKPOINT)
			animation_component.play_attack_animation(player_sprite)
			pass
		PLAYER_STATE.DEFLECT_ATTACK:
			input_component.set_disable_input(true)
			input_component.set_disable_movement(true)
			SoundManager.play_clip(sound_player, SoundManager.SOUND_DAMAGE)
			animation_component.play_deflect_animation(player_sprite)
			pass
		PLAYER_STATE.KNEELING:
			input_component.set_disable_movement(true)
			input_component.set_disable_input(true)
			animation_component.play_kneel_animation(player_sprite)
			pass


func on_attack_timer_finished() -> void:
	set_state(PLAYER_STATE.IDLE)


func on_invincible(invincible_status: bool) -> void: 
	if invincible_status:
		animation_component.play_hurt_animation(player_sprite, animation_player_invincible)
		animation_player_invincible.play("invincible")
	else:
		animation_player_invincible.stop()


func on_hurt(hurt_status: bool) -> void:
	if hurt_status:
		velocity = player_hitbox_component.get_hurt_jump_velocity()
		set_state(PLAYER_STATE.HURT)
	else:
		set_state(PLAYER_STATE.IDLE)


func get_current_direction() -> Vector2:
	if player_sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT

func updateMeleeHitbox() -> void:
	var direction: Vector2 = get_current_direction()
	if direction.x == 1:
		player_melee_attack.position = Vector2(10.0, 0.0)
	elif direction.x == -1:
		player_melee_attack.position = Vector2(-10.0, 0.0)


# Attack
func handle_perform_attack() -> void:
	if input_component.get_ranged_attack_input():
		attack_component.start_attack("ranged")
		set_state(PLAYER_STATE.RANGED_ATTACK)
	if input_component.get_melee_attack_input():
		attack_component.start_attack("melee")
		set_state(PLAYER_STATE.MELEE_ATTACK)
	if input_component.get_deflect_attack_input():
		attack_component.start_attack("deflect")
		set_state(PLAYER_STATE.DEFLECT_ATTACK)

func handle_kneeling_action() -> void:
	if input_component.get_kneel_input():
		set_state(PLAYER_STATE.KNEELING)
		_movement_disabled = true
	else:
		_movement_disabled = false
		calculate_states()
		


# Inputs
#func get_jump_input() -> bool:
	#if _disable_input:
		#return false
	#return Input.is_action_just_pressed("jump")
#
#func get_jump_input_released() -> bool:
	#if _disable_input:
		#return false
	#return Input.is_action_just_released("jump")
##
#func get_ranged_attack_input() -> bool:
	#if _disable_input:
		#return false
	#return Input.is_action_just_pressed("ranged_attack")
#
#func get_melee_attack_input() -> bool:
	#if _disable_input:
		#return false
	#return Input.is_action_just_pressed("melee_attack") and !Input.is_key_pressed(KEY_SHIFT)
#
#func get_deflect_attack_input() -> bool:
	#if _disable_input:
		#return false
	#return Input.is_action_just_pressed("deflect_attack")
#

