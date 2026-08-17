extends Node3D

## Barebones scaffold every example lesson scene inherits: camera, light, a
## ground plane, and a UI overlay with the lesson title and a way back.

@export var lesson_title: String = "Lesson"
@export var chapter_id: String = ""
@export var lesson_id: String = ""

@onready var title_label: Label = $UI/Margin/HeaderRow/TitleLabel
@onready var back_button: Button = $UI/Margin/HeaderRow/BackButton
@onready var complete_button: Button = $UI/Margin/HeaderRow/CompleteButton


func _ready() -> void:
	title_label.text = lesson_title
	back_button.pressed.connect(_on_back_pressed)
	complete_button.pressed.connect(_on_complete_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_complete_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")
