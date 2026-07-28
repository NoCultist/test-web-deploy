extends Node

const SCENES := ["res://Main.tscn", "res://Scene2.tscn"]

var current_index := 0
var next_scene_button: Button
var _js_callbacks := []

func _ready() -> void:
	TranslationServer.add_translation(load("res://localization/strings.en.translation"))
	TranslationServer.add_translation(load("res://localization/strings.pl.translation"))
	TranslationServer.set_locale("en")

	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.14, 0.19)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6

	var button := Button.new()
	button.name = "NextSceneButton"
	button.custom_minimum_size = Vector2(140, 40)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.position = Vector2(16, 16)
	canvas.add_child(button)
	button.pressed.connect(_on_next_scene_pressed)
	next_scene_button = button
	_refresh_button()

	if OS.has_feature("web"):
		_setup_js_bridge()

func _setup_js_bridge() -> void:
	var window := JavaScriptBridge.get_interface("window")
	# create_callback() results must be kept alive (stored, not just assigned
	# inline) or the JS-side function reference goes dead silently.
	# Each exposed function takes zero arguments: passing primitives (like
	# strings) through the callback's args array comes through as an opaque
	# JavaScriptObject rather than a native GDScript String, so distinct
	# no-arg functions per action sidestep that marshaling issue entirely.
	var cb_green = JavaScriptBridge.create_callback(_js_set_box_green)
	var cb_red = JavaScriptBridge.create_callback(_js_set_box_red)
	var cb_play_pause = JavaScriptBridge.create_callback(_js_toggle_play_pause)
	var cb_lang_en = JavaScriptBridge.create_callback(_js_set_language_en)
	var cb_lang_pl = JavaScriptBridge.create_callback(_js_set_language_pl)
	var cb_next_scene = JavaScriptBridge.create_callback(_js_next_scene)
	var cb_camera = JavaScriptBridge.create_callback(_js_cycle_camera)
	_js_callbacks = [cb_green, cb_red, cb_play_pause, cb_lang_en, cb_lang_pl, cb_next_scene, cb_camera]

	window.gameSetBoxGreen = cb_green
	window.gameSetBoxRed = cb_red
	window.gameTogglePlayPause = cb_play_pause
	window.gameSetLanguageEn = cb_lang_en
	window.gameSetLanguagePl = cb_lang_pl
	window.gameNextScene = cb_next_scene
	window.gameCycleCamera = cb_camera

func _js_set_box_green(_args: Array) -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_on_green_pressed"):
		scene.call("_on_green_pressed")

func _js_set_box_red(_args: Array) -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_on_red_pressed"):
		scene.call("_on_red_pressed")

func _js_toggle_play_pause(_args: Array) -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_on_play_pause_pressed"):
		scene.call("_on_play_pause_pressed")

func _js_set_language_en(_args: Array) -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_on_lang_pressed"):
		scene.call("_on_lang_pressed", "en")

func _js_set_language_pl(_args: Array) -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_on_lang_pressed"):
		scene.call("_on_lang_pressed", "pl")

func _js_next_scene(_args: Array) -> void:
	_on_next_scene_pressed()

func _js_cycle_camera(_args: Array) -> void:
	var rigs := get_tree().get_nodes_in_group("camera_rig")
	if rigs.size() > 0 and rigs[0].has_method("_cycle_preset"):
		rigs[0].call("_cycle_preset")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and next_scene_button:
		_refresh_button()

func _refresh_button() -> void:
	next_scene_button.text = tr("NEXT_SCENE")

func _on_next_scene_pressed() -> void:
	current_index = (current_index + 1) % SCENES.size()
	get_tree().change_scene_to_file(SCENES[current_index])
