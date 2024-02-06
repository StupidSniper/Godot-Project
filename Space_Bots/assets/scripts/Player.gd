extends CharacterBody3D

var speed
var speed_multiplier = 1
const WALK_SPEED = 4.0
const SPRINT_SPEED = 5.5
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

var powerslide_multiplier = 1.5

const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

const BASE_FOV = 80.0
const FOV_CHANGE = 1.5

const DEFUALT_HEIGHT = 1.0
const  CROUCHED_HEIGHT = 0.7

var is_crouched = false
var can_crouch = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

var gun_pos = Vector3(0.4, -0.45, -0.5)

@onready var crouch_timer = $"Crouch Timer"
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var gun = $"Head/Camera3D/Shooting Object/Gun Holder/Revolver"
@onready var player_walk_part = $player_walk_particles

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
	if Input.is_action_pressed("crouch") and can_crouch:
		is_crouched = true
		var can_powerslide = can_powerslide()
	else:
		is_crouched = false
		
	if Input.is_action_just_released("crouch") and can_crouch:
		can_crouch = false
		crouch_timer.start()
		
	if is_crouched:
		scale.y = lerp(scale.y, CROUCHED_HEIGHT, delta * 10)
	else:
		scale.y = lerp(scale.y, DEFUALT_HEIGHT, delta * 10)
		
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_still = is_still()
	if !is_still && is_on_floor():
		player_walk_part.emitting = true
	else:
		player_walk_part.emitting = false
	
	if is_on_floor():
		if direction:
			velocity.x = lerp(-velocity.x, direction.x * speed, delta * 75) * speed_multiplier
			velocity.z = lerp(-velocity.z, direction.z * speed, delta * 75)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	gun.transform.origin = _headbob(t_bob) / 2
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	lerp_velocity()

	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _on_crouch_timer_timeout():
	can_crouch = true
	
func is_still() -> bool:
	if velocity.x < 0.5 and velocity.x > -0.5 and velocity.z < 0.5 and velocity.z > -0.5:
		return true
	else:
		return false
		
func lerp_velocity():
	if velocity.x < 0.05 and velocity.x > -0.05:
		velocity.x = 0.0
		
	if velocity.z < 0.05 and velocity.z > -0.05:
		velocity.z = 0.0
		
func can_powerslide() -> bool:
	return true
