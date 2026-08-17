class_name CharacterAnimHelper
extends RefCounted

const ANIM_FILES := {
	"idle": "res://assets/character/idle.fbx",
	"run": "res://assets/character/run.fbx",
	"jump": "res://assets/character/jump.fbx",
}

## Shared blend-space axis positions, single source of truth for both the
## AnimationNodeBlendSpace1D layout (build_blend_tree) and callers driving it
## (Character.gd, RemotePlayer.gd) so both sides agree on where each clip sits.
const BLEND_POSITIONS := {
	"idle": 0.0,
	"run": 1.0,
	"jump": 2.0,
}
const BLEND_LERP_SPEED := 6.0

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

## Builds an AnimationTree driving anim_player through a 1D blend space laid
## out per BLEND_POSITIONS, so transitions between idle/run/jump crossfade
## instead of hard-cutting. Added as a sibling of anim_player; caller drives
## it every frame via set_blend_position().
static func build_blend_tree(anim_player: AnimationPlayer) -> AnimationTree:
	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.min_space = BLEND_POSITIONS["idle"]
	blend_space.max_space = BLEND_POSITIONS["jump"]
	for anim_name in BLEND_POSITIONS:
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = anim_name
		blend_space.add_blend_point(anim_node, BLEND_POSITIONS[anim_name])

	var tree := AnimationTree.new()
	tree.tree_root = blend_space
	anim_player.add_sibling(tree, true)
	tree.anim_player = tree.get_path_to(anim_player)
	tree.active = true
	return tree

## Smoothly moves the tree's blend_position toward the target state
## ("idle"/"run"/"jump"), returning the new position for the caller to store.
static func step_blend(tree: AnimationTree, current_position: float, target_state: String, delta: float) -> float:
	var target: float = BLEND_POSITIONS.get(target_state, 0.0)
	var next_position := move_toward(current_position, target, BLEND_LERP_SPEED * delta)
	tree.set("parameters/blend_position", next_position)
	return next_position
