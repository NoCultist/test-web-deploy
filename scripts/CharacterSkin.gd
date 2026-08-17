class_name CharacterSkin
extends RefCounted

const DEFAULT_TEXTURE := "res://assets/character/humanMaleA.png"

static func create_material(tint: Color = Color(1, 1, 1, 1)) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(DEFAULT_TEXTURE)
	mat.roughness = 0.9
	mat.albedo_color = tint
	return mat
