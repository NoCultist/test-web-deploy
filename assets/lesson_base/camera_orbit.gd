extends Node3D

@export var mouse_button: MouseButton = MOUSE_BUTTON_LEFT
@export var orbit_sensitivity: float = 0.008
@export var min_pitch_degrees: float = -80.0
@export var max_pitch_degrees: float = 10.0

var _dragging := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == mouse_button:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		rotation.y -= event.relative.x * orbit_sensitivity
		rotation.x = clamp(
			rotation.x - event.relative.y * orbit_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
