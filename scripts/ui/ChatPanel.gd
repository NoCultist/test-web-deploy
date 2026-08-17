extends PanelContainer

@onready var chat_log: RichTextLabel = $VBoxContainer/ChatLog
@onready var chat_input: LineEdit = $VBoxContainer/ChatInput

func _ready() -> void:
	chat_input.text_submitted.connect(_on_chat_submitted)
	MultiplayerService.chat_updated.connect(_on_chat_updated)

func _on_chat_submitted(text: String) -> void:
	chat_input.text = ""
	chat_input.release_focus()
	MultiplayerService.send_chat(text)

func _on_chat_updated(messages: Array) -> void:
	chat_log.clear()
	for msg in messages:
		var id: String = str(msg.get("id", "?"))
		var text: String = str(msg.get("text", "")).replace("[", "[lb]")
		var short_id := id.substr(0, 6)
		chat_log.append_text("[color=#8ab4ff]%s:[/color] %s\n" % [short_id, text])
