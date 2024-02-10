extends CharacterBody3D

#basic movement consts
const SPRINT_SPEED = 2
const SLIDE_BOOST = 1
const WALLRUN_BOOST = 1
const JUMP_FORCE = 4.5

#mouse consts
const MOUSE_SENS = 0.005
const MOUSE_CLAMP = Vector2(-50, 60)

#gravity consts
const GRAVITY = 9.8

#crouch consts
const CROUCH_SPEED = -3
const CROUCH_HEIGHT = .7

#crouch lerp consts
const CROUCH_LERP_WEIGHT = 10

#headbob consts
const BOB_AMP = 0.04
const BOB_FREQ = 2.0
var t_bob = 0.0

#crouch timer reference
@onready var crouch_timer = $"Crouch Timer"
@onready var head = $Head
@onready var camera = $"Head/Cam Holder/Camera3D"
@onready var player_walk_part = $player_walk_particles
@onready var cam_holder = $"Head/Cam Holder"
@onready var gun_holder = $"Head/Cam Holder/Camera3D/Shooting Object/Gun Holder"

#walk consts
const WALK_SPEED = 8
const WALK_HEIGHT = 1.0

#camera tilt consts
const CAMERA_TILT = 0.05
const CAMERA_LERP_WEIGHT = 5

#weapon sway consts
const DEFAULT_WEAPON_POS = Vector3(0.5, -0.33, -0.5)
const WEAPON_SWAY_AMOUNT = 0.02
const WEAPON_SWAY_WEIGHT = 10

#walk lerp consts
const MOVE_LERP_WEIGHT = 10
const AIR_LERP_WEIGHT = 3

#runtime variables

#runtime movement variables

#runtime vector3s
var input_vec3 = Vector3()
var movement_vector = Vector3()
var horizontal_movement_vec = Vector3()
var vertical_movement_vec = Vector3()
var jump_vec = Vector3()
var camera_roation_vec = Vector3()
var gun_roation_vec = Vector3()

var mouse_input = Vector2()

#runtime bools for player states
var is_crouched = false
var is_sprinting = false

#runtime gravity variables
var gravity = 9.8

#runtime speed variable
var speed = 10

var move_lerp_multi = 1

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
			mouse_input = event.relative
	
	#clamping camera roation
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(MOUSE_CLAMP.x), deg_to_rad(MOUSE_CLAMP.y))

func _physics_process(delta):
	t_bob += delta * velocity.length() * float(is_on_floor())
	speed = WALK_SPEED
	#getting input
	var input_vec = Input.get_vector("left", "right", "up", "down")
	input_vec3 = Vector3(input_vec.x, 0, input_vec.y)
	
	
	#camera rotation movement stuff
	input_vec3 = (head.transform.basis * input_vec3).normalized()
	
	#sprinting
	if Input.is_action_pressed("sprint"):
		speed += SPRINT_SPEED
	
	#crouch input
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	else:
		is_crouched = false
	
	
	#jumping
	if Input.is_action_pressed("jump") and is_on_floor():
		jump_vec.y = JUMP_FORCE
	else:
		jump_vec.y = 0
	
	#crouch speed movement penelty
	if is_crouched:
		speed += CROUCH_SPEED
		
	#calling the crouch function with the least amount of spagetti as possible
	crouch(delta)
	
	#getting the horizontal movement through interpolation
	if is_on_floor():
		horizontal_movement_vec = lerp(horizontal_movement_vec, input_vec3 * Vector3(speed, 0, speed), MOVE_LERP_WEIGHT * move_lerp_multi * delta)
		#fixing jumping
		vertical_movement_vec.y = clamp(vertical_movement_vec.y, 0, 10000)
	
	#reducing control if in the air
	if not is_on_floor():
		horizontal_movement_vec = lerp(horizontal_movement_vec, input_vec3 * Vector3(speed, 0, speed), AIR_LERP_WEIGHT * move_lerp_multi * delta)
	
	
	if not is_on_floor() or not moving():
		#disable player walk particles
		player_walk_part.emitting = false
	else:
		#enable player walk particles
		player_walk_part.emitting = true
	
	#gravity
	if not is_on_floor():
		vertical_movement_vec.y -= gravity * delta
	
	#making the movement vector
	vertical_movement_vec += jump_vec
	movement_vector = horizontal_movement_vec + vertical_movement_vec
	
	#making the player full stop if its below a specific speed
	if movement_vector.length() <= 0.005 and movement_vector.length() >= -0.005:
		movement_vector.x = 0
		movement_vector.z = 0
	
	#setting velocity to the movement vector
	velocity = movement_vector
	
	move_and_slide()
	camera_tilt(input_vec, delta)
	gun_tilt(input_vec, delta)
	weapon_sway(delta)
	headbob()
	gunbob()

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

func camera_tilt(input_vec, delta):
	#camera tilt
	camera_roation_vec.z = lerpf(camera.rotation.z, -input_vec.x * CAMERA_TILT, CAMERA_LERP_WEIGHT * delta)
	camera.rotation.z = camera_roation_vec.z

#gun tiltcamera_roation_vec
func gun_tilt(input_vec, delta):
	gun_roation_vec.z = lerpf(camera.rotation.z, -input_vec.x * CAMERA_TILT, (CAMERA_LERP_WEIGHT + 5) * delta)
	gun_holder.rotation.z = gun_roation_vec.z

#weapon sway
func weapon_sway(delta):
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10 * delta)
	gun_holder.rotation.x = lerp(gun_holder.rotation.x, mouse_input.y * WEAPON_SWAY_AMOUNT * -1, WEAPON_SWAY_WEIGHT * delta)
	gun_holder.rotation.y = lerp(gun_holder.rotation.y, mouse_input.x * WEAPON_SWAY_AMOUNT * -1, WEAPON_SWAY_WEIGHT * delta)

#headbob
func headbob():
	if moving():
		camera.transform.origin.y = sin(t_bob * BOB_FREQ) * BOB_AMP
		camera.transform.origin.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP

func gunbob():
	if moving():
		gun_holder.transform.origin.y = sin(t_bob * BOB_FREQ) * BOB_AMP / 2 + DEFAULT_WEAPON_POS.y 
		gun_holder.transform.origin.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP / 2 + DEFAULT_WEAPON_POS.x

#basic check if player is moving. You need to check if the movement of the player is less than 0._ because of the interpolation movement
func moving() -> bool:
	if velocity.length() <= 0.5 and velocity.length() >= -0.5:
		return false
	else:
		return true
