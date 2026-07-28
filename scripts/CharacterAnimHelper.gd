class_name CharacterAnimHelper
extends RefCounted

const ANIM_FILES := {
	"idle": "res://assets/character/idle.fbx",
	"run": "res://assets/character/run.fbx",
	"jump": "res://assets/character/jump.fbx",
}

static func load_animations(anim_player: AnimationPlayer) -> void:
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
