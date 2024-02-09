extends CharacterBody3D

#basic movement consts
const SPRINT_SPEED = 4.5
const SLIDE_BOOST = 1
const WALLRUN_BOOST = 1
const JUMP_FORCE = 4.5

#mouse consts
const MOUSE_SENS = 0.005
const MOUSE_CLAMP = Vector2(-30, 60)

#gravity consts
const GRAVITY = 9.8

#crouch consts
const CROUCH_SPEED = -2
const CROUCH_HEIGHT = .7

#crouch lerp consts
const CROUCH_LERP_WEIGHT = 10

#crouch timer reference
@onready var crouch_timer = $"Crouch Timer"

#camera roation head/camera reference
@onready var head = $Head
@onready var camera = $Head/Camera3D

#walk consts
const WALK_SPEED = 10
const WALK_HEIGHT = 1.0

#walk lerp consts
const MOVE_LERP_WEIGHT = 10

#runtime variables

#runtime movement variables

#runtime vector3s
var input_vec3 = Vector3()
var movement_vector = Vector3()
var horizontal_movement_vec = Vector3()
var vertical_movement_vec = Vector3()

#runtime bools for player states
var is_crouched = false
var is_sprinting = false

#runtime gravity variables
var gravity = 9.8

#runtime speed variable
var speed = 10

func _ready():
	pass


#mouse inputs
func _unhandled_input(event):
	
	#locking mouse
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	#roationg camera and head based on mouse inputs
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			head.rotate_y(-event.relative.x * MOUSE_SENS)
			camera.rotate_x(-event.relative.y * MOUSE_SENS)
	
	#clamping camera roation
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(MOUSE_CLAMP.x), deg_to_rad(MOUSE_CLAMP.y))

func _physics_process(delta):
	#getting input
	var input_vec = Input.get_vector("left", "right", "up", "down")
	input_vec3 = Vector3(input_vec.x, 0, input_vec.y).normalized()
	
	#crouch input
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	else:
		is_crouched = false
		
	#calling the crouch function with the least amount of spagetti as possible
	crouch(delta)
	
	#getting the horizontal movement through interpolation
	horizontal_movement_vec = lerp(horizontal_movement_vec, input_vec3 * Vector3(WALK_SPEED, 0, WALK_SPEED), MOVE_LERP_WEIGHT * delta)
	
	#jumping
	if Input.is_action_pressed("jump") and is_on_floor():
		vertical_movement_vec.y = JUMP_FORCE
		
	#gravity
	if not is_on_floor():
		vertical_movement_vec.y -= gravity * delta
	
	#making the movement vector
	movement_vector = horizontal_movement_vec + vertical_movement_vec
	
	#camera rotation movement stuff
	movement_vector = (head.transform.basis * movement_vector)
	
	#setting velocity to the movement vector
	velocity = movement_vector
	
	move_and_slide()

#crouch lerp handling
func crouch(delta):
	#doign the lerp for crouch for smooth motionww
	if is_crouched:
		scale.y = lerp(scale.y, CROUCH_HEIGHT, CROUCH_LERP_WEIGHT * delta)
		if scale.y <= (CROUCH_HEIGHT + 0.01):
			scale.y = CROUCH_HEIGHT
	else:
		scale.y = lerp(scale.y, WALK_HEIGHT, CROUCH_LERP_WEIGHT * delta)
		if scale.y >= (WALK_HEIGHT - 0.01):
			scale.y = 1
