extends Node3D

@onready var top_box: MeshInstance3D = $TopBox

@onready var play_pause_button: Button = $UI/HBoxContainer/PlayPauseButton
@onready var green_box_button: Button = $UI/HBoxContainer/GreenBoxButton
@onready var red_box_button: Button = $UI/HBoxContainer/RedBoxButton
@onready var spawn_dancers_button: Button = $UI/HBoxContainer/SpawnDancersButton
@onready var lang_en_button: Button = $UI/LangBox/LangEnButton
@onready var lang_pl_button: Button = $UI/LangBox/LangPlButton

const DANCER_SCENE := preload("res://breakdance_footwork_2.tscn")
const DANCERS_PER_SPAWN := 10

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
	spawn_dancers_button.pressed.connect(_on_spawn_dancers_pressed)
	lang_en_button.pressed.connect(_on_lang_pressed.bind("en"))
	lang_pl_button.pressed.connect(_on_lang_pressed.bind("pl"))

	for button in [play_pause_button, green_box_button, red_box_button, spawn_dancers_button, lang_en_button, lang_pl_button]:
		button.pressed.connect(_play_click_sfx)

	sfx_player.stream = load("res://assets/audio/click.ogg")

	Localization.locale_changed.connect(_on_locale_changed)
	WebBridge.expose("gameSetBoxGreen", _on_green_pressed)
	WebBridge.expose("gameSetBoxRed", _on_red_pressed)
	WebBridge.expose("gameTogglePlayPause", _on_play_pause_pressed)

func _process(delta: float) -> void:
	if is_rotating:
		top_box.rotate_y(delta * rotation_speed)

func _on_play_pause_pressed() -> void:
	is_rotating = not is_rotating

func _on_green_pressed() -> void:
	top_box.material_override = green_material

func _on_red_pressed() -> void:
	top_box.material_override = red_material

func _on_spawn_dancers_pressed() -> void:
	for i in range(DANCERS_PER_SPAWN):
		var dancer: Node3D = DANCER_SCENE.instantiate()
		add_child(dancer, true)
		dancer.position = Vector3(randf_range(-7.0, 7.0), 0.0, randf_range(-6.0, 4.0))
		dancer.rotation.y = randf_range(0.0, TAU)

func _on_lang_pressed(locale: String) -> void:
	Localization.set_locale(locale)

func _on_locale_changed(locale: String) -> void:
	_refresh_ui_text()
	voice_player.stream = load(VOICE_CLIPS[locale])
	voice_player.play()

func _play_click_sfx() -> void:
	sfx_player.play()

func _refresh_ui_text() -> void:
	play_pause_button.text = tr("PLAY_PAUSE")
	green_box_button.text = tr("GREEN_BOX")
	red_box_button.text = tr("RED_BOX")
	spawn_dancers_button.text = tr("SPAWN_DANCERS")
