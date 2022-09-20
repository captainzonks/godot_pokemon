extends KinematicBody2D

var tall_grass = preload("res://Scenes/TallGrass.tscn")

signal player_moving_signal
signal player_stopped_signal

export var walk_speed = 0.03
export var jump_speed = 0.03
const TILE_SIZE = 16

onready var anim_tree = $AnimationTree
onready var anim_state = anim_tree.get("parameters/playback")
onready var ray = $BlockingRayCast2D
onready var ledge_ray = $LedgeRayCast2D

var jumping_over_ledge: bool = false

var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false
var percent_moved_to_next_tile = 0.0

enum PlayerState {
	IDLE,
	TURNING,
	WALKING
}

enum FacingDirection {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

# Called when the node enters the scene tree for the first time.
func _ready():
	anim_tree.active = true
	initial_position = position


func _physics_process(delta):
	if player_state == PlayerState.TURNING:
		return
	elif is_moving == false:
		process_player_input()
	elif input_direction != Vector2.ZERO:
		anim_state.travel("Walk")
		move(delta)
	else:
		anim_state.travel("Idle")
		is_moving = false


func process_player_input():
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))

	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		anim_tree.set("parameters/Turn/blend_position", input_direction)

		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		else:
			initial_position = position
			is_moving = true
	else:
		anim_state.travel("Idle")


func finished_turning():
	player_state = PlayerState.IDLE


func need_to_turn():
	var new_facing_direction
	if input_direction.x < 0:
		new_facing_direction = FacingDirection.LEFT
	elif input_direction.x > 0:
		new_facing_direction = FacingDirection.RIGHT
	elif input_direction.y < 0:
		new_facing_direction = FacingDirection.UP
	elif input_direction.y > 0:
		new_facing_direction = FacingDirection.DOWN

	if facing_direction != new_facing_direction:
		facing_direction = new_facing_direction
		return true
	facing_direction = new_facing_direction
	return false


func move(delta):
	var desired_step: Vector2 = input_direction * TILE_SIZE / 2
	ray.cast_to = desired_step
	ray.force_raycast_update()
	
	ledge_ray.cast_to = desired_step
	ledge_ray.force_raycast_update()
	
	if ledge_ray.is_colliding() and input_direction == Vector2(0, 1) or jumping_over_ledge:
		percent_moved_to_next_tile += jump_speed + delta
		if percent_moved_to_next_tile >= 2.0:
			position = initial_position + input_direction * TILE_SIZE * 2
			percent_moved_to_next_tile = 0.0
			is_moving = false
			jumping_over_ledge = false
		else:
			jumping_over_ledge = true
			var input = input_direction.y * TILE_SIZE * percent_moved_to_next_tile
			position.y = initial_position.y + (-0.93 - 0.53 * input + 0.05 * pow(input, 2))
	elif !ray.is_colliding():
		if percent_moved_to_next_tile == 0.0:
			emit_signal("player_moving_signal")
		percent_moved_to_next_tile += walk_speed + delta
		if percent_moved_to_next_tile >= 0.1:
			emit_signal("player_stopped_signal")
		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + TILE_SIZE * input_direction
			percent_moved_to_next_tile = 0.0
			is_moving = false
		else:
			position = initial_position + TILE_SIZE * input_direction * percent_moved_to_next_tile
	else:
		percent_moved_to_next_tile = 0.0
		is_moving = false
		


