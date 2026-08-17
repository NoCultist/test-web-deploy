extends HBoxContainer

@onready var next_scene_button: Button = $NextSceneButton
@onready var fullscreen_button: Button = $FullscreenButton

func _ready() -> void:
	next_scene_button.pressed.connect(_on_next_scene_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	_refresh_text()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_text()

func _refresh_text() -> void:
	next_scene_button.text = tr("NEXT_SCENE")
	fullscreen_button.text = tr("FULLSCREEN")

func _on_next_scene_pressed() -> void:
	SceneRouter.next_scene()

func _on_fullscreen_pressed() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
