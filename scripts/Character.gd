extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var mesh_instance: MeshInstance3D = $Model/Root/Skeleton3D/characterMedium
@onready var land_particles: GPUParticles3D = $LandParticles

const SPEED := 4.0
const ACCELERATION := 10.0
const JUMP_VELOCITY := 4.5
const TURN_SPEED := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var current_anim_state := ""
var was_on_floor := true

func _ready() -> void:
	add_to_group("player")

	var skin := StandardMaterial3D.new()
	skin.albedo_texture = load("res://assets/character/humanMaleA.png")
	skin.roughness = 0.9
	mesh_instance.material_override = skin

	CharacterAnimHelper.load_animations(anim_player)
	_play_anim("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var cam_basis: Basis = _get_camera_basis()
	var move_dir: Vector3 = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y)
	move_dir.y = 0.0
	move_dir = move_dir.normalized()

	if move_dir.length_squared() > 0.001:
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
		var target_basis: Basis = Transform3D().looking_at(-move_dir, Vector3.UP).basis
		global_transform.basis = global_transform.basis.slerp(target_basis, TURN_SPEED * delta).orthonormalized()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * ACCELERATION * delta)

	move_and_slide()

	var now_on_floor := is_on_floor()
	if now_on_floor and not was_on_floor:
		land_particles.restart()
		land_particles.emitting = true
	was_on_floor = now_on_floor

	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if not now_on_floor:
		_play_anim("jump")
	elif is_moving:
		_play_anim("run")
	else:
		_play_anim("idle")

func _get_camera_basis() -> Basis:
	var rigs := get_tree().get_nodes_in_group("camera_rig")
	if rigs.size() > 0:
		return (rigs[0] as Node3D).global_transform.basis
	return global_transform.basis

func _play_anim(anim_name: String) -> void:
	if anim_name == current_anim_state:
		return
	current_anim_state = anim_name
	anim_player.play(anim_name)
