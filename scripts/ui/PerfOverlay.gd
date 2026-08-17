extends Label

func _process(_delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	var frame_ms := (1000.0 / fps) if fps > 0 else 0.0
	var mem_mb := OS.get_static_memory_usage() / 1048576.0
	text = "FPS: %d\nFrame: %.1f ms\nMem: %.1f MB" % [fps, frame_ms, mem_mb]
