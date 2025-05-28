# Settings panel for configuration

Create a new scene for the settings panel (res://addons/character_setup_plugin/settings_panel.tscn) with a Control-based UI.

Scene Structure:
Root: VBoxContainer (named SettingsPanel).
Child: Label (title, e.g., “Character Setup Plugin Settings”).
Child: VBoxContainer (for settings fields).
HBoxContainer: Label (“OpenAI API Key”) + LineEdit (password mode, named ApiKeyField).
HBoxContainer: Label (“Scan Method”) + OptionButton (named ScanMethodField).
HBoxContainer: Label (“Image Extensions”) + LineEdit (named ImageExtensionsField).
HBoxContainer: Label (“Audio Extensions”) + LineEdit (named AudioExtensionsField).
Child: Button (text: “Save”, named SaveButton).
