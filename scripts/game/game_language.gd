extends Node

const LANGUAGES := {"en": "English", "fr": "Français"}
const DEFAULT := "en"
const PREFERENCE_PATH := "user://language.cfg"

func _enter_tree() -> void:
	var settings := ConfigFile.new()
	var language := DEFAULT
	if FileAccess.file_exists(PREFERENCE_PATH) and settings.load(PREFERENCE_PATH) == OK:
		var saved: Variant = settings.get_value("interface", "language", DEFAULT)
		if saved is String and LANGUAGES.has(saved):
			language = saved
	TranslationServer.set_locale(language)

static func choose(language: String) -> void:
	if not LANGUAGES.has(language):
		return
	TranslationServer.set_locale(language)
	var settings := ConfigFile.new()
	settings.set_value("interface", "language", language)
	if settings.save(PREFERENCE_PATH) != OK:
		push_warning("Could not save the language preference.")
