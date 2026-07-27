extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var mesh_instance: MeshInstance3D = $Skeleton3D/Ch11

func _ready() -> void:
	_fix_material_transparency()

	var lib: AnimationLibrary = anim_player.get_animation_library("")
	var clip_names := lib.get_animation_list()
	if clip_names.is_empty():
		return

	# Mixamo FBX exports often include a static "Take 001" alongside the
	# real "mixamo_com" clip. Pick whichever clip actually has motion
	# (most tracks with more than one keyframe) instead of just the first.
	var best_name: StringName = clip_names[0]
	var best_moving_tracks := -1
	for clip_name in clip_names:
		var anim: Animation = lib.get_animation(clip_name)
		var moving_tracks := 0
		for i in range(anim.get_track_count()):
			if anim.track_get_key_count(i) > 1:
				moving_tracks += 1
		if moving_tracks > best_moving_tracks:
			best_moving_tracks = moving_tracks
			best_name = clip_name

	var anim: Animation = lib.get_animation(best_name)
	anim.loop_mode = Animation.LOOP_LINEAR
	anim_player.play(best_name)

func _fix_material_transparency() -> void:
	# The FBX material bakes albedo alpha at 0.8, which auto-enables
	# alpha-blend transparency. Blended surfaces don't depth-sort per
	# triangle, so overlapping limbs/torso render see-through. Force opaque.
	var mesh: Mesh = mesh_instance.mesh
	for i in range(mesh.get_surface_count()):
		var src_mat := mesh.surface_get_material(i)
		if src_mat is StandardMaterial3D:
			var mat: StandardMaterial3D = src_mat.duplicate()
			mat.albedo_color.a = 1.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			mesh_instance.set_surface_override_material(i, mat)
