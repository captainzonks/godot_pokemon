extends AnimatedSprite



# Called when the node enters the scene tree for the first time.
func _ready():
	frame = 0
	playing = true


func _on_Grass_Effect_animation_finished():
	queue_free()
