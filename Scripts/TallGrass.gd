extends Node2D


func player_exiting_grass():
	get_tree().current_scene.get_node("/root/LevelBase/InteractiveTerrain/Player/Grass").visible = false


func player_in_grass():
	get_tree().current_scene.get_node("/root/LevelBase/InteractiveTerrain/Player/Grass").visible = true


func _on_Area2D_area_entered(area):
	pass
	#player_in_grass()


func _on_Area2D_area_exited(area):
	pass
	#player_exiting_grass()
