extends Node3D

@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var mesh_instance: MeshInstance3D = $Model/Root/Skeleton3D/characterMedium

const LERP_SPEED := 8.0

var target_position: Vector3
var target_rotation_y: float
var target_anim := "idle"
var current_anim_state := ""
var _has_target := false
var skin_material: StandardMaterial3D
var anim_tree: AnimationTree
var _blend_position := 0.0

func _ready() -> void:
	skin_material = CharacterSkin.create_material(Color(0.65, 0.8, 1.0))
	mesh_instance.material_override = skin_material

	CharacterAnimHelper.load_animations(anim_player)
	anim_tree = CharacterAnimHelper.build_blend_tree(anim_player)
	_play_anim("idle")

func set_custom_skin(tex: Texture2D) -> void:
	skin_material.albedo_texture = tex
	skin_material.albedo_color = Color(1, 1, 1, 1)

func set_target(pos: Vector3, ry: float, anim: String = "idle") -> void:
	target_position = pos
	target_rotation_y = ry
	target_anim = anim
	if not _has_target:
		global_position = pos
		rotation.y = ry
		_has_target = true

func _process(delta: float) -> void:
	global_position = global_position.lerp(target_position, LERP_SPEED * delta)
	rotation.y = lerp_angle(rotation.y, target_rotation_y, LERP_SPEED * delta)
	_play_anim(target_anim)
	_blend_position = CharacterAnimHelper.step_blend(anim_tree, _blend_position, current_anim_state, delta)

func _play_anim(anim_name: String) -> void:
	current_anim_state = anim_name
