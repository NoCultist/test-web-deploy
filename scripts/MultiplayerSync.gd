extends Node

const SYNC_INTERVAL := 0.2
const REMOTE_PLAYER_SCENE := preload("res://RemotePlayer.tscn")

var _sync_timer := 0.0
var _remote_players := {}
var _last_scene: Node = null

func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_sync_timer += delta
	if _sync_timer < SYNC_INTERVAL:
		return
	_sync_timer = 0.0
	_push_local_position()
	_pull_remote_positions()

func _push_local_position() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node3D = players[0]
	var pos := player.global_position
	var ry := player.rotation.y
	# Godot runs inside the landing page's iframe, so "window" here is the
	# iframe's own window - the Firebase glue lives on the parent page.
	var code := "if (window.parent.mpUpdate) window.parent.mpUpdate(%f, %f, %f, %f);" % [pos.x, pos.y, pos.z, ry]
	JavaScriptBridge.eval(code, true)

func _pull_remote_positions() -> void:
	var result = JavaScriptBridge.eval(
		"(window.parent.mpGetPlayersJSON ? window.parent.mpGetPlayersJSON() : '{}')", true
	)
	if typeof(result) != TYPE_STRING:
		return
	var parsed = JSON.parse_string(result)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene != _last_scene:
		_remote_players.clear()
		_last_scene = scene

	var seen_ids := {}
	for id in parsed:
		seen_ids[id] = true
		var data: Dictionary = parsed[id]
		var pos := Vector3(data.get("x", 0.0), data.get("y", 0.0), data.get("z", 0.0))
		var ry: float = data.get("ry", 0.0)
		if not _remote_players.has(id):
			var ghost := REMOTE_PLAYER_SCENE.instantiate()
			scene.add_child(ghost)
			_remote_players[id] = ghost
		_remote_players[id].set_target(pos, ry)

	for id in _remote_players.keys():
		if not seen_ids.has(id):
			_remote_players[id].queue_free()
			_remote_players.erase(id)
