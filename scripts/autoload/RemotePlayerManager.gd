extends Node

## Owns remote-player ghost visualization: the only file that knows
## RemotePlayer.tscn exists. Reacts to MultiplayerService's network-state
## signals, has no Firebase/JS knowledge of its own.

const REMOTE_PLAYER_SCENE := preload("res://RemotePlayer.tscn")

var _remote_players := {}
var _remote_skins := {}
var _last_scene: Node = null

func _ready() -> void:
	MultiplayerService.player_updated.connect(_on_player_updated)
	MultiplayerService.player_left.connect(_on_player_left)
	MultiplayerService.skin_updated.connect(_on_skin_updated)

func _on_player_updated(id: String, pos: Vector3, ry: float, anim: String) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene != _last_scene:
		# The previous scene's ghosts were freed along with it when
		# SceneRouter switched scenes - just drop the stale references.
		_remote_players.clear()
		_last_scene = scene

	if not _remote_players.has(id):
		var ghost := REMOTE_PLAYER_SCENE.instantiate()
		scene.add_child(ghost, true)
		_remote_players[id] = ghost
		if _remote_skins.has(id):
			ghost.set_custom_skin(_remote_skins[id])

	_remote_players[id].set_target(pos, ry, anim)

func _on_player_left(id: String) -> void:
	if _remote_players.has(id):
		_remote_players[id].queue_free()
		_remote_players.erase(id)
	_remote_skins.erase(id)

func _on_skin_updated(id: String, tex: Texture2D) -> void:
	_remote_skins[id] = tex
	if _remote_players.has(id):
		_remote_players[id].set_custom_skin(tex)
