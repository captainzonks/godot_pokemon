extends "res://Scripts/Actor.gd"

var tall_grass = preload("res://Scenes/TallGrass.tscn")

signal player_moving_signal
signal player_stopped_signal
signal player_entering_door_signal
signal player_entered_door_signal

export var walk_speed = 0.03
export var jump_speed = 0.03
const TILE_SIZE = 16

onready var anim_tree = $AnimationTree
onready var anim_state = anim_tree.get("parameters/playback")
onready var ledge_ray = $LedgeRayCast2D
onready var shadow = $Shadow
onready var door_ray = $DoorRayCast2D

var jumping_over_ledge: bool = false

var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false
var stop_input = false
var percent_moved_to_next_tile = 0.0

var timer: Timer

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
	shadow.visible = false


func _physics_process(delta):
	if player_state == PlayerState.TURNING or stop_input:
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
	blocking_ray.cast_to = desired_step
	blocking_ray.force_raycast_update()

	ledge_ray.cast_to = desired_step
	ledge_ray.force_raycast_update()
	
	door_ray.cast_to = desired_step
	door_ray.force_raycast_update()
	
	if door_ray.is_colliding():
		if percent_moved_to_next_tile == 0.0:
			emit_signal("player_entering_door_signal")
		percent_moved_to_next_tile += walk_speed + delta
		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + input_direction * TILE_SIZE
			percent_moved_to_next_tile = 0.0
			is_moving = false
			stop_input = true
			$AnimationPlayer.play("Door")
			$Camera2D.clear_current()
		else:
			position = initial_position + TILE_SIZE * input_direction * percent_moved_to_next_tile

	elif ledge_ray.is_colliding() and input_direction == Vector2(0, 1) or jumping_over_ledge:
		percent_moved_to_next_tile += jump_speed + delta
		if percent_moved_to_next_tile >= 2.0:
			position = initial_position + input_direction * TILE_SIZE * 2
			percent_moved_to_next_tile = 0.0
			is_moving = false
			jumping_over_ledge = false
			shadow.visible = false
		else:
			shadow.visible = true
			jumping_over_ledge = true
			var input = input_direction.y * TILE_SIZE * percent_moved_to_next_tile

			if !timer and percent_moved_to_next_tile <= 1:
				timer = Timer.new()
				timer.connect("timeout",self,"jump_ledge_animation")
				timer.wait_time = 0.1
				timer.one_shot = true
				add_child(timer)
				timer.start()

			position.y = initial_position.y + input
	elif !blocking_ray.is_colliding():
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

func jump_ledge_animation():
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.connect("finished", self, "jump_ledge_completed")
	tween.tween_property($Character, "offset", Vector2(0, -14), 0.1)

func jump_ledge_completed():
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($Character, "offset", Vector2(0, -6), 0.2)
	timer = null
	
func entered_door():
	print("emitting door signal")
	emit_signal("player_entered_door_signal")
