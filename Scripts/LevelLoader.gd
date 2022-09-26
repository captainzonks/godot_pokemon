extends Node2D
export var player = "res://Scenes/Player.tscn"

var next_scene = null

# Called when the node enters the scene tree for the first time.
func _ready():
	instantiate_player()
	#$ScreenTransition/ColorRect.color = Color(0,0,0,0)


func instantiate_player():
	# This sets the player to appear at the correct area when loading into a new
	# zone
	var spawn_points = $"Non-InteractiveTerrain".get_children()
	var index = GameData.zone_load_spawn_point
	
	# If we somehow don't have that spawn point, fall back to 0
	if not spawn_points[index]:
		index = 0
		
	# Spawn the player and add to scene
	var player_spawn = load(player).instance()
	$InteractiveTerrain.add_child(player_spawn)
	# Set player at the correct position (spawn point of zone)
	player_spawn.position = spawn_points[index].position
	# Make the player face the direction from last movement to create a
	# "seamless" feel
	if GameData.zone_load_facing_direction:
		player_spawn.update_facing(GameData.zone_load_facing_direction)


func transition_to_scene(new_scene: String):
	next_scene = new_scene
	$ScreenTransition/AnimationPlayer.play("FadeToBlack")


func finished_fading():
	$CurrentScene.get_child(0).queue_free()
	$CurrentScene.add_child(load(next_scene).instance())
	$ScreenTransition/AnimationPlayer.play("FadeToNormal")
