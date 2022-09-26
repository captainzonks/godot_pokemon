extends "res://Scripts/OverworldObject.gd"

const TallGrass = preload("res://Scripts/TallGrass.gd")

onready var sprite = $Pivot/Sprite
onready var blocking_ray = $BlockingRayCast2D

enum DIR { UP, DOWN, LEFT, RIGHT }
# Allow changing the default facing direction in editor
export(DIR) var dir = DIR.DOWN

# Here you can set which frames represent facing direction
export var down_frame = 0
export var up_frame = 4
export var horiz_frame = 2

var vert_frame_last_time = false

func _ready():
	# Set up z index here and simply match it to the y value
	# This allows moving characters like the player to be drawn over
	# a sprite when "in front", but if they move behind that character
	# it will correctly update (sort y order for non-cells)
	z_as_relative = false
	set_z_index(position.y)


# Actor targets a position to move to
func target_position(move_vector):
	var target = overworld.request_move(self, move_vector)
	# Whether we can move or not, update our facing first
	update_facing(move_vector)
	if target:
		move_to(target)
	else:
		bump()


# Change how the character is facing
func update_facing(direction):
	if direction.x == 1:
		sprite.set("scale", Vector2(1,1))
		sprite.frame = horiz_frame
		dir = DIR.RIGHT
	elif direction.x == -1:
		sprite.set("scale", Vector2(1,1))
		sprite.frame = horiz_frame
		dir = DIR.LEFT
	elif direction.y == 1:
		if vert_frame_last_time:
			sprite.set("scale", Vector2(-1,1))
			vert_frame_last_time = false
		else:
			sprite.set("scale", Vector2(1,1))
			vert_frame_last_time = true
		sprite.frame = down_frame
		dir = DIR.DOWN
	elif direction.y == -1:
		if vert_frame_last_time:
			sprite.set("scale", Vector2(-1,1))
			vert_frame_last_time = false
		else:
			sprite.set("scale", Vector2(1,1))
			vert_frame_last_time = true
		sprite.frame = up_frame
		dir = DIR.UP


# Smoothly moves actor to target position
func move_to(target_position):
	# Begin movement. Actor is non-interactive while moving.
	set_process(false)
	process_movement_animation()

	# Move the node to the target cell instantly,
	# and animate the sprite moving from the start to the target cell
	var move_direction = (target_position - position).normalized()
	var current_pos = - move_direction * overworld.cell_size * 2

	# Keep the pivot where it is, because we are about to move the whole
	# transform and it will cause a glitchy animation where the sprite warps
	# for a single frame to the target location (with the transform) and then
	# smoothly animates after
	$Pivot.position = current_pos

	# Move the pivot point from the current position to 0,0
	# (relative to parent transform) basically just catch up with the parent
	$Tween.interpolate_property($Pivot, "position", current_pos, Vector2(),
			$AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR)
	position = target_position

	# This is basically a "sort y order" option for children (non_cells)
	set_z_index(position.y)
	$Tween.start()

	# Stop the function execution until the animation finished
	yield($AnimationPlayer, "animation_finished")
	# Movement complete. Actor is again "interactive"
	set_process(true)


# Define what an actor should do if it is interacted with in the child class
func interact():
	print("I am an Actor with no interact defined.")


# Failure to move function
func bump():
	pass
	# set_process(false)
	# $AnimationPlayer.play("bump")
	# yield($AnimationPlayer, "animation_finished")
	# set_process(true)


# Movement animation processing
func process_movement_animation():
	match dir:
		DIR.UP:
			$AnimationPlayer.play("WalkUp")
		DIR.DOWN:
			$AnimationPlayer.play("WalkDown")
		DIR.LEFT:
			$AnimationPlayer.play("WalkLeft")
		DIR.RIGHT:
			$AnimationPlayer.play("WalkRight")


func _on_Area2D_area_entered(area):
	yield(get_tree().create_timer(0.01), "timeout")	
	if area.get_parent().get_parent().is_in_group("grass"):
		$Pivot/Sprite/Grass.visible = true


func _on_Area2D_area_exited(area):
	if area.get_parent().get_parent().is_in_group("grass"):
		$Pivot/Sprite/Grass.visible = false
