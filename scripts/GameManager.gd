extends Node

const SCENES := ["res://Main.tscn", "res://Scene2.tscn"]

var current_index := 0
var next_scene_button: Button
var fullscreen_button: Button
var perf_label: Label
var chat_log: RichTextLabel
var chat_input: LineEdit
var _js_callbacks := []
var _chat_poll_timer := 0.0
var _last_chat_count := 0

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

	var top_left_box := HBoxContainer.new()
	top_left_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left_box.position = Vector2(16, 16)
	top_left_box.add_theme_constant_override("separation", 10)
	canvas.add_child(top_left_box)

	var button := Button.new()
	button.name = "NextSceneButton"
	button.custom_minimum_size = Vector2(140, 40)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	top_left_box.add_child(button)
	button.pressed.connect(_on_next_scene_pressed)
	next_scene_button = button

	var fs_button := Button.new()
	fs_button.name = "FullscreenButton"
	fs_button.custom_minimum_size = Vector2(140, 40)
	fs_button.add_theme_stylebox_override("normal", style)
	fs_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	top_left_box.add_child(fs_button)
	fs_button.pressed.connect(_on_fullscreen_pressed)
	fullscreen_button = fs_button

	_refresh_button()

	var chat_panel := PanelContainer.new()
	chat_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	chat_panel.position = Vector2(16, 70)
	var chat_panel_style := StyleBoxFlat.new()
	chat_panel_style.bg_color = Color(0.08, 0.1, 0.14, 0.85)
	chat_panel_style.corner_radius_top_left = 6
	chat_panel_style.corner_radius_top_right = 6
	chat_panel_style.corner_radius_bottom_right = 6
	chat_panel_style.corner_radius_bottom_left = 6
	chat_panel_style.content_margin_left = 8
	chat_panel_style.content_margin_right = 8
	chat_panel_style.content_margin_top = 6
	chat_panel_style.content_margin_bottom = 6
	chat_panel.add_theme_stylebox_override("panel", chat_panel_style)
	canvas.add_child(chat_panel)

	var chat_vbox := VBoxContainer.new()
	chat_panel.add_child(chat_vbox)

	chat_log = RichTextLabel.new()
	chat_log.custom_minimum_size = Vector2(300, 150)
	chat_log.scroll_following = true
	chat_log.bbcode_enabled = true
	chat_log.add_theme_color_override("default_color", Color(1, 1, 1, 1))
	chat_log.add_theme_font_size_override("normal_font_size", 13)
	chat_vbox.add_child(chat_log)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Type message, Enter to send..."
	chat_input.custom_minimum_size = Vector2(300, 32)
	chat_input.max_length = 200
	chat_input.text_submitted.connect(_on_chat_submitted)
	chat_vbox.add_child(chat_input)

	perf_label = Label.new()
	perf_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1))
	perf_label.add_theme_font_size_override("font_size", 14)
	perf_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	perf_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	perf_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	perf_label.position = Vector2(-160, -60)
	perf_label.custom_minimum_size = Vector2(150, 50)
	perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(perf_label)

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

func _process(delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	var frame_ms := (1000.0 / fps) if fps > 0 else 0.0
	var mem_mb := OS.get_static_memory_usage() / 1048576.0
	perf_label.text = "FPS: %d\nFrame: %.1f ms\nMem: %.1f MB" % [fps, frame_ms, mem_mb]

	if OS.has_feature("web"):
		_chat_poll_timer += delta
		if _chat_poll_timer >= 0.5:
			_chat_poll_timer = 0.0
			_poll_chat()

func _on_chat_submitted(text: String) -> void:
	text = text.strip_edges()
	chat_input.text = ""
	if text.is_empty() or not OS.has_feature("web"):
		return
	var escaped := text.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ")
	var code := "if (window.parent.mpSendChat) window.parent.mpSendChat('%s');" % escaped
	JavaScriptBridge.eval(code, true)

func _poll_chat() -> void:
	var result = JavaScriptBridge.eval(
		"(window.parent.mpGetChatJSON ? window.parent.mpGetChatJSON() : '[]')", true
	)
	if typeof(result) != TYPE_STRING:
		return
	var parsed = JSON.parse_string(result)
	if typeof(parsed) != TYPE_ARRAY:
		return
	if parsed.size() == _last_chat_count:
		return
	_last_chat_count = parsed.size()
	chat_log.clear()
	for msg in parsed:
		var id: String = str(msg.get("id", "?"))
		var text: String = str(msg.get("text", "")).replace("[", "[lb]")
		var short_id := id.substr(0, 6)
		chat_log.append_text("[color=#8ab4ff]%s:[/color] %s\n" % [short_id, text])

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and next_scene_button:
		_refresh_button()

func _refresh_button() -> void:
	next_scene_button.text = tr("NEXT_SCENE")
	fullscreen_button.text = tr("FULLSCREEN")

func _on_next_scene_pressed() -> void:
	current_index = (current_index + 1) % SCENES.size()
	get_tree().change_scene_to_file(SCENES[current_index])

func _on_fullscreen_pressed() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
