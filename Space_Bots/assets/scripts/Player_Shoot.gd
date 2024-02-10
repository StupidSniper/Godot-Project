extends Node3D

var damage = 1

var can_shoot = true

var is_reloading = false

var bullet_count
const MAX_BULLETS = 6
const RELOAD_SPEED = 1


var auto_reload = true


@onready var timer = $Firerate
@onready var raycast = $RayCast3D
@onready var head = $"../.."
@onready var camera = $".."
@onready var reload_timer = $"Reload Timer"
@onready var cam_holder = $"../.."
@onready var animation = $"../../../../AnimationPlayer"
@onready var gun_holder = $"Gun Holder"

var bullet_decal = preload("res://assets/scenes/bullet_decal.tscn")
var bullet_part = preload("res://assets/scenes/bullet_particle.tscn")
var enemy_part = preload("res://assets/scenes/enemy_particle.tscn")

func _ready():
	bullet_count = MAX_BULLETS
	reload_timer.wait_time = RELOAD_SPEED

func _physics_process(delta):
	if Input.is_action_pressed("use") && can_shoot && bullet_count > 0:
		can_shoot = false
		timer.start()
		shoot()
		
	if auto_reload and bullet_count <= 0 && not is_reloading:
		reload()
		is_reloading = true
		
	if Input.is_action_just_pressed("reload") && is_reloading == false:
		reload()
		is_reloading = true

func _on_firerate_timeout():
	can_shoot = true

func shoot():
	bullet_count -= 1
	cam_holder.recoil()
	animation.play("Gun Shoot")
	if raycast.is_colliding():
		var col_point = raycast.get_collision_point()
		var normal = raycast.get_collision_normal()
		var target = raycast.get_collider()
		
		if target != null:
			if target.is_in_group("Enemy") && target.has_method("enemy_hit"):
				hit_enemy(damage, col_point, normal, target)
				
			if !target.is_in_group("Enemy") && !target.has_method("enemy_hit"):
				hit_non_enemy(damage, col_point, normal, target)


func hit_enemy(damage, col_point, normal, target):
	target.enemy_hit(damage)
	
	var enemy_part_instantiate = enemy_part.instantiate()
	enemy_part_instantiate.global_position = col_point
	get_tree().current_scene.add_child(enemy_part_instantiate)
	
	enemy_part_instantiate.look_at(col_point + normal, Vector3.UP)
	enemy_part_instantiate.look_at(col_point + normal, Vector3.RIGHT)


func hit_non_enemy(damage, col_point, normal, target):
	var bullet_part_instantiate = bullet_part.instantiate()
	var bullet_decal_instantiate = bullet_decal.instantiate()
	
	bullet_part_instantiate.global_position = col_point
	get_tree().current_scene.add_child(bullet_part_instantiate)
	
	bullet_part_instantiate.look_at(col_point + normal, Vector3.UP)
	bullet_part_instantiate.look_at(col_point + normal, Vector3.RIGHT)
	
	bullet_decal_instantiate.global_position = col_point
	get_tree().current_scene.add_child(bullet_decal_instantiate)
	
	bullet_decal_instantiate.look_at(col_point + normal, Vector3.UP)
	bullet_decal_instantiate.look_at(col_point + normal, Vector3.RIGHT)


func reload():
	reload_timer.start()
	animation.play("Gun Reload")


func _on_reload_timer_timeout():
	bullet_count = MAX_BULLETS
	is_reloading = false
