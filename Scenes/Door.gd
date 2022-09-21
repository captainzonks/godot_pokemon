extends Area2D

export(String, FILE) var next_scene_path = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	var player = find_parent("CurrentScene").get_children().back().find_node("Player")
	player.connect("player_entering_door_signal", self, "enter_door")
	player.connect("player_entered_door_signal", self, "close_door")
	
func enter_door():
	pass

func close_door():
	$AnimationPlayer.play("DoorClosed")

func door_closed():
	print("transitioning to next scene")
	get_node(NodePath("/root/SceneManager")).transition_to_scene(next_scene_path)
