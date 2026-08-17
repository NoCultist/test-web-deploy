extends Node

## Network-state layer only: polls Firebase (via WebBridge) and reports state
## through signals. Knows nothing about RemotePlayer scenes or ghost
## lifecycle - see RemotePlayerManager for that.

signal player_updated(id: String, pos: Vector3, ry: float, anim: String)
signal player_left(id: String)
signal skin_updated(id: String, tex: Texture2D)
signal chat_updated(messages: Array)

const SYNC_INTERVAL := 0.2
const SKIN_POLL_INTERVAL := 1.0
const REMOTE_SKIN_POLL_INTERVAL := 5.0
const CHAT_POLL_INTERVAL := 0.5

var _sync_timer := 0.0
var _skin_poll_timer := 0.0
var _remote_skin_poll_timer := 0.0
var _chat_poll_timer := 0.0
var _last_local_skin := ""
var _last_chat_count := 0
var _seen_remote_ids := {}

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

	_chat_poll_timer += delta
	if _chat_poll_timer >= CHAT_POLL_INTERVAL:
		_chat_poll_timer = 0.0
		_poll_chat()

func send_chat(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty():
		return
	WebBridge.call_parent("mpSendChat", [text])

func _push_local_position() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node3D = players[0]
	var pos := player.global_position
	var ry := player.rotation.y
	var anim: String = player.current_anim_state if "current_anim_state" in player else "idle"
	WebBridge.call_parent("mpUpdate", [pos.x, pos.y, pos.z, ry, anim])

func _pull_remote_positions() -> void:
	var result = WebBridge.call_parent("mpGetPlayersJSON")
	if typeof(result) != TYPE_STRING:
		return
	var parsed = JSON.parse_string(result)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var seen_ids := {}
	for id in parsed:
		seen_ids[id] = true
		var data: Dictionary = parsed[id]
		var pos := Vector3(data.get("x", 0.0), data.get("y", 0.0), data.get("z", 0.0))
		var ry: float = data.get("ry", 0.0)
		var anim: String = data.get("anim", "idle")
		player_updated.emit(id, pos, ry, anim)

	for id in _seen_remote_ids.keys():
		if not seen_ids.has(id):
			player_left.emit(id)

	_seen_remote_ids = seen_ids

func _check_local_skin() -> void:
	var result = WebBridge.call_parent("mpGetMySkin")
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
	var result = WebBridge.call_parent("mpGetSkinsJSON")
	if typeof(result) != TYPE_STRING:
		return
	var parsed = JSON.parse_string(result)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for id in parsed:
		var data_url: String = parsed[id]
		var tex := SkinHelper.decode_skin_texture(data_url)
		if tex:
			skin_updated.emit(id, tex)

func _poll_chat() -> void:
	var result = WebBridge.call_parent("mpGetChatJSON")
	if typeof(result) != TYPE_STRING:
		return
	var parsed = JSON.parse_string(result)
	if typeof(parsed) != TYPE_ARRAY:
		return
	if parsed.size() == _last_chat_count:
		return
	_last_chat_count = parsed.size()
	chat_updated.emit(parsed)
