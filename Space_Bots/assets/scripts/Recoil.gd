extends Node3D

var current_rot = Vector3()
var target_rot = Vector3()

@export var recoil_x : float
@export var recoil_y : float
@export var recoil_z : float

const SNAPPINESS = 10
const RETURN_SPEED = 4

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	target_rot = lerp(target_rot, Vector3.ZERO, RETURN_SPEED * delta)
	current_rot = current_rot.slerp(target_rot, SNAPPINESS * delta)
	rotation = current_rot


func recoil():
	rng.randomize()
	target_rot += Vector3(recoil_x, rng.randf_range(-recoil_y, recoil_y), rng.randf_range(-recoil_z, recoil_z))
