extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var mesh_instance: MeshInstance3D = $Model/Root/Skeleton3D/characterMedium
@onready var camera_yaw: Node3D = get_node("/root/Main/CameraYaw")

const ANIM_FILES := {
	"idle": "res://assets/character/idle.fbx",
	"run": "res://assets/character/run.fbx",
	"jump": "res://assets/character/jump.fbx",
}

const SPEED := 4.0
const ACCELERATION := 10.0
const JUMP_VELOCITY := 4.5
const TURN_SPEED := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var current_anim_state := ""

func _ready() -> void:
	var skin := StandardMaterial3D.new()
	skin.albedo_texture = load("res://assets/character/humanMaleA.png")
	skin.roughness = 0.9
	mesh_instance.material_override = skin

	var lib: AnimationLibrary
	if anim_player.has_animation_library(""):
		lib = anim_player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		anim_player.add_animation_library("", lib)

	for anim_name in ANIM_FILES:
		var src_inst: Node = (load(ANIM_FILES[anim_name]) as PackedScene).instantiate()
		var src_player: AnimationPlayer = src_inst.get_node("AnimationPlayer")
		var src_lib: AnimationLibrary = src_player.get_animation_library("")
		for clip_name in src_lib.get_animation_list():
			if str(clip_name).findn("targeting") == -1:
				var anim: Animation = src_lib.get_animation(clip_name)
				anim.loop_mode = Animation.LOOP_LINEAR
				lib.add_animation(anim_name, anim)
				break
		src_inst.queue_free()

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

	var cam_basis: Basis = camera_yaw.global_transform.basis
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

	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if not is_on_floor():
		_play_anim("jump")
	elif is_moving:
		_play_anim("run")
	else:
		_play_anim("idle")

func _play_anim(anim_name: String) -> void:
	if anim_name == current_anim_state:
		return
	current_anim_state = anim_name
	anim_player.play(anim_name)
