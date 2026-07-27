extends Node

const SCENES := ["res://Main.tscn", "res://Scene2.tscn"]

var current_index := 0
var next_scene_button: Button

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and next_scene_button:
		_refresh_button()

func _refresh_button() -> void:
	next_scene_button.text = tr("NEXT_SCENE")

func _on_next_scene_pressed() -> void:
	current_index = (current_index + 1) % SCENES.size()
	get_tree().change_scene_to_file(SCENES[current_index])
