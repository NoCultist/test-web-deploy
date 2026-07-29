extends Node

const SYNC_INTERVAL := 0.2
const SKIN_POLL_INTERVAL := 1.0
const REMOTE_SKIN_POLL_INTERVAL := 5.0
const REMOTE_PLAYER_SCENE := preload("res://RemotePlayer.tscn")

var _sync_timer := 0.0
var _skin_poll_timer := 0.0
var _remote_skin_poll_timer := 0.0
var _remote_players := {}
var _remote_skins := {}
var _last_local_skin := ""
var _last_scene: Node = null

func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_sync_timer += delta
	if _sync_timer >= SYNC_INTERVAL:
		_sync_timer = 0.0
		_push_local_position()
		_pull_remote_positions()

	_skin_poll_timer += delta
	if _skin_poll_timer >= SKIN_POLL_INTERVAL:
		_skin_poll_timer = 0.0
		_check_local_skin()

	_remote_skin_poll_timer += delta
	if _remote_skin_poll_timer >= REMOTE_SKIN_POLL_INTERVAL:
		_remote_skin_poll_timer = 0.0
		_check_remote_skins()

func _check_local_skin() -> void:
	var result = JavaScriptBridge.eval(
		"(window.parent.mpGetMySkin ? window.parent.mpGetMySkin() : '')", true
	)
	if typeof(result) != TYPE_STRING or result == "" or result == _last_local_skin:
		return
	_last_local_skin = result
	var tex := SkinHelper.decode_skin_texture(result)
	if tex == null:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("set_custom_skin"):
		players[0].set_custom_skin(tex)

func _check_remote_skins() -> void:
	var result = JavaScriptBridge.eval(
		"(window.parent.mpGetSkinsJSON ? window.parent.mpGetSkinsJSON() : '{}')", true
	)
	if typeof(result) != TYPE_STRING:
		return
	var parsed = JSON.parse_string(result)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for id in parsed:
		var data_url: String = parsed[id]
		if _remote_skins.get(id, "") == data_url:
			continue
		_remote_skins[id] = data_url
		if _remote_players.has(id):
			var tex := SkinHelper.decode_skin_texture(data_url)
			if tex:
				_remote_players[id].set_custom_skin(tex)

func _push_local_position() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node3D = players[0]
	var pos := player.global_position
	var ry := player.rotation.y
	var anim: String = player.current_anim_state if "current_anim_state" in player else "idle"
	# Godot runs inside the landing page's iframe, so "window" here is the
	# iframe's own window - the Firebase glue lives on the parent page.
	var code := "if (window.parent.mpUpdate) window.parent.mpUpdate(%f, %f, %f, %f, '%s');" % [pos.x, pos.y, pos.z, ry, anim]
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
		var anim: String = data.get("anim", "idle")
		if not _remote_players.has(id):
			var ghost := REMOTE_PLAYER_SCENE.instantiate()
			scene.add_child(ghost)
			_remote_players[id] = ghost
			if _remote_skins.has(id):
				var tex := SkinHelper.decode_skin_texture(_remote_skins[id])
				if tex:
					ghost.set_custom_skin(tex)
		_remote_players[id].set_target(pos, ry, anim)

	for id in _remote_players.keys():
		if not seen_ids.has(id):
			_remote_players[id].queue_free()
			_remote_players.erase(id)
