extends Node2D

signal set_grass_z_index

var player_inside: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().current_scene.find_node("Player").connect("player_moving_signal", self, "player_exiting_grass")
	get_tree().current_scene.find_node("Player").connect("player_stopped_signal", self, "player_in_grass")


func player_exiting_grass():
	player_inside = false	
	get_tree().current_scene.find_node("Player").get_node("Grass").visible = false


func player_in_grass():
	if player_inside == true:
		get_tree().current_scene.find_node("Player").get_node("Grass").visible = true


func _on_Area2D_body_entered(body):
	player_inside = true

