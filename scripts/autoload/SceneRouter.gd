extends Node

const SCENES := ["res://Main.tscn", "res://Scene2.tscn"]

var current_index := 0

func _ready() -> void:
	WebBridge.expose("gameNextScene", next_scene)

func next_scene() -> void:
	current_index = (current_index + 1) % SCENES.size()
	get_tree().change_scene_to_file(SCENES[current_index])
