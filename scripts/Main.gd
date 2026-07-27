extends Node3D

@onready var top_box: MeshInstance3D = $TopBox

@onready var play_pause_button: Button = $UI/HBoxContainer/PlayPauseButton
@onready var green_box_button: Button = $UI/HBoxContainer/GreenBoxButton
@onready var red_box_button: Button = $UI/HBoxContainer/RedBoxButton
@onready var lang_en_button: Button = $UI/LangBox/LangEnButton
@onready var lang_pl_button: Button = $UI/LangBox/LangPlButton

@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var voice_player: AudioStreamPlayer = $VoicePlayer

var is_rotating := true
var rotation_speed := 1.0

var red_material := StandardMaterial3D.new()
var green_material := StandardMaterial3D.new()

const VOICE_CLIPS := {
	"en": "res://assets/audio/voice_en.ogg",
	"pl": "res://assets/audio/voice_pl.ogg",
}

func _ready() -> void:
	red_material.albedo_color = Color(0.65, 0.08, 0.1)
	green_material.albedo_color = Color(0.15, 0.5, 0.18)
	top_box.material_override = red_material

	_refresh_ui_text()

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	green_box_button.pressed.connect(_on_green_pressed)
	red_box_button.pressed.connect(_on_red_pressed)
	lang_en_button.pressed.connect(_on_lang_pressed.bind("en"))
	lang_pl_button.pressed.connect(_on_lang_pressed.bind("pl"))

	for button in [play_pause_button, green_box_button, red_box_button, lang_en_button, lang_pl_button]:
		button.pressed.connect(_play_click_sfx)

	sfx_player.stream = load("res://assets/audio/click.ogg")

func _process(delta: float) -> void:
	if is_rotating:
		top_box.rotate_y(delta * rotation_speed)

func _on_play_pause_pressed() -> void:
	is_rotating = not is_rotating

func _on_green_pressed() -> void:
	top_box.material_override = green_material

func _on_red_pressed() -> void:
	top_box.material_override = red_material

func _on_lang_pressed(locale: String) -> void:
	TranslationServer.set_locale(locale)
	_refresh_ui_text()
	voice_player.stream = load(VOICE_CLIPS[locale])
	voice_player.play()

func _play_click_sfx() -> void:
	sfx_player.play()

func _refresh_ui_text() -> void:
	play_pause_button.text = tr("PLAY_PAUSE")
	green_box_button.text = tr("GREEN_BOX")
	red_box_button.text = tr("RED_BOX")
