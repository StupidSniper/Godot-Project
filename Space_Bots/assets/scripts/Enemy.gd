extends RigidBody3D

var health = 15
# Called when the node enters the scene tree for the first time.
func enemy_hit(damage):
	health -= damage
	if health <= 0:
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
