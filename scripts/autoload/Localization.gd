extends Node

signal locale_changed(locale: String)

func _ready() -> void:
	TranslationServer.add_translation(load("res://localization/strings.en.translation"))
	TranslationServer.add_translation(load("res://localization/strings.pl.translation"))
	TranslationServer.set_locale("en")

	WebBridge.expose("gameSetLanguageEn", _set_locale.bind("en"))
	WebBridge.expose("gameSetLanguagePl", _set_locale.bind("pl"))

func _set_locale(locale: String) -> void:
	set_locale(locale)

func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)
