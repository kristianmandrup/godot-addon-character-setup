extends Control

@onready var api_key_field: LineEdit = %ApiKeyField
@onready var scan_method_field: OptionButton = %ScanMethodField
@onready var image_extensions_field: LineEdit = %ImageExtensionsField
@onready var audio_extensions_field: LineEdit = %AudioExtensionsField
@onready var save_button: Button = %SaveButton

func _ready():
    # Initialize scan method dropdown
    scan_method_field.add_item("Modified Time", Scanner.ComparisonMethod.MODIFIED_TIME)
    scan_method_field.add_item("File Hash", Scanner.ComparisonMethod.FILE_HASH)
    
    # Load existing settings
    api_key_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", "")
    scan_method_field.select(ProjectSettings.get_setting("plugins/character_setup_plugin/scan_method", Scanner.ComparisonMethod.MODIFIED_TIME))
    image_extensions_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/image_extensions", [".png", ".jpg", ".jpeg", ".bmp"]).join(",")
    audio_extensions_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/audio_extensions", [".wav", ".ogg", ".mp3"]).join(",")
    
    # Connect save button
    save_button.pressed.connect(_on_save_pressed)

func _on_save_pressed():
    # Save settings to ProjectSettings
    ProjectSettings.set_setting("plugins/character_setup_plugin/api_key", api_key_field.text)
    ProjectSettings.set_setting("plugins/character_setup_plugin/scan_method", scan_method_field.selected)
    
    # Parse and validate extensions
    var image_exts = image_extensions_field.text.split(",", false).map(func(ext): return "." + ext.strip_edges().trim_prefix("."))
    var audio_exts = audio_extensions_field.text.split(",", false).map(func(ext): return "." + ext.strip_edges().trim_prefix("."))
    ProjectSettings.set_setting("plugins/character_setup_plugin/image_extensions", image_exts)
    ProjectSettings.set_setting("plugins/character_setup_plugin/audio_extensions", audio_exts)
    
    # Save project settings
    ProjectSettings.save()
    
    print("Character Setup Plugin: Settings saved.")
    
    # Notify plugin to reinitialize (optional rescan)
    var plugin = get_node_or_null("/root/EditorNode/CharacterSetupPlugin")
    if plugin:
        plugin.reinitialize_scanner()