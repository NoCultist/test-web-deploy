extends Node3D

@onready var camera_pitch: Node3D = $CameraPitch
@onready var camera: Camera3D = $CameraPitch/Camera3D

const FOLLOW_HEIGHT := 1.4
const FOLLOW_SPEED := 5.0
const MOUSE_SENSITIVITY := 0.005
const PITCH_LIMIT := 1.396  # ~80 degrees
const TWEEN_TIME := 0.6

# Each preset: [yaw_degrees, pitch_degrees, distance]
const PRESETS := [
	[0.0, -6.0, 6.5],
	[0.0, -35.0, 9.5],
	[90.0, -10.0, 7.0],
	[180.0, -8.0, 5.5],
]

var dragging := false
var preset_index := 0
var tween: Tween

func _ready() -> void:
	add_to_group("camera_rig")
	WebBridge.expose("gameCycleCamera", _cycle_preset)

func _process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node3D = players[0]
	var target: Vector3 = player.global_position + Vector3(0, FOLLOW_HEIGHT, 0)
	global_position = global_position.lerp(target, FOLLOW_SPEED * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		var new_pitch: float = camera_pitch.rotation.x - event.relative.y * MOUSE_SENSITIVITY
		camera_pitch.rotation.x = clamp(new_pitch, -PITCH_LIMIT, PITCH_LIMIT)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		_cycle_preset()

func _cycle_preset() -> void:
	preset_index = (preset_index + 1) % PRESETS.size()
	var preset: Array = PRESETS[preset_index]
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", deg_to_rad(preset[0]), TWEEN_TIME)
	tween.tween_property(camera_pitch, "rotation:x", deg_to_rad(preset[1]), TWEEN_TIME)
	tween.tween_property(camera, "position:z", preset[2], TWEEN_TIME)
