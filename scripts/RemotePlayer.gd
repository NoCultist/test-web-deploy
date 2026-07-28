extends Node3D

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var mesh_instance: MeshInstance3D = $Model/Root/Skeleton3D/characterMedium

const LERP_SPEED := 8.0

var target_position: Vector3
var target_rotation_y: float
var current_anim_state := ""
var _has_target := false

func _ready() -> void:
	var skin := StandardMaterial3D.new()
	skin.albedo_texture = load("res://assets/character/humanMaleA.png")
	skin.roughness = 0.9
	skin.albedo_color = Color(0.65, 0.8, 1.0)
	mesh_instance.material_override = skin

	CharacterAnimHelper.load_animations(anim_player)
	_play_anim("idle")

func set_target(pos: Vector3, ry: float) -> void:
	target_position = pos
	target_rotation_y = ry
	if not _has_target:
		global_position = pos
		rotation.y = ry
		_has_target = true

func _process(delta: float) -> void:
	var moved_dist := global_position.distance_to(target_position)
	global_position = global_position.lerp(target_position, LERP_SPEED * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation_y, LERP_SPEED * delta)

	if moved_dist > 0.05:
		_play_anim("run")
	else:
		_play_anim("idle")

func _play_anim(anim_name: String) -> void:
	if anim_name == current_anim_state:
		return
	current_anim_state = anim_name
	anim_player.play(anim_name)
