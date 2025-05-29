extends Control

@onready var api_key_field: LineEdit = %ApiKeyField
@onready var scan_method_field: OptionButton = %ScanMethodField
@onready var image_extensions_field: LineEdit = %ImageExtensionsField
@onready var audio_extensions_field: LineEdit = %AudioExtensionsField
@onready var collision_shape_field: OptionButton = %CollisionShapeField
@onready var collision_color_field: ColorPickerButton = %CollisionColorField
@onready var hit_color_field: ColorPickerButton = %HitColorField
@onready var area_color_field: ColorPickerButton = %AreaColorField
@onready var asset_map_path_field: LineEdit = %AssetMapPathField
# GAS settings
@onready var gas_url_field: LineEdit = %GASURLField
@onready var gas_api_key_field: LineEdit = %GASAPIKeyField

@onready var save_button: Button = %SaveButton

@mcp_command("update_asset_map")
func update_asset_map(params: Dictionary) -> Dictionary:
    var sync_gas = params.get("sync_gas", false) as bool
    var updater = AssetMapUpdater.new()
    return await updater.update_asset_map(sync_gas)

func _ready():
    # Initialize scan method dropdown
    scan_method_field.add_item("Modified Time", Scanner.ComparisonMethod.MODIFIED_TIME)
    scan_method_field.add_item("File Hash", Scanner.ComparisonMethod.FILE_HASH)
    
    # Initialize collision shape dropdown
    collision_shape_field.add_item("Rectangle", 0)
    collision_shape_field.add_item("Capsule", 1)
    collision_shape_field.add_item("Circle", 2)
    
    # Load existing settings
    api_key_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", "")
    scan_method_field.select(ProjectSettings.get_setting("plugins/character_setup_plugin/scan_method", Scanner.ComparisonMethod.MODIFIED_TIME))
    image_extensions_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/image_extensions").join(",")
    audio_extensions_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/audio_extensions").join(",")
    var shape_type = ProjectSettings.get_setting("plugins/character_setup_plugin/collision_shape_type", "rectangle").to_lower()
    match shape_type:
        "capsule": collision_shape_field.select(1)
        "circle": collision_shape_field.select(2)
        _: collision_shape_field.select(0)  # Default to rectangle

	collision_color_field.color = ProjectSettings.get_setting("plugins/character_setup_plugin/collision_box_color", Color.BLUE)
    hit_color_field.color = ProjectSettings.get_setting("plugins/character_setup_plugin/hit_box_color", Color.RED)
    area_color_field.color = ProjectSettings.get_setting("plugins/character_setup_plugin/detection_area_color", Color.GREEN)    
	asset_map_path_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/asset_map_path", "res://game_asset_map.json")

	# GAS settings
	gas_url_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/gas_url", "")
    gas_api_key_field.text = ProjectSettings.get_setting("plugins/character_setup_plugin/gas_api_key", "")

    # Connect save button
    save_button.pressed.connect(_on_save_pressed)

func _validate_extensions(extensions: Array[String]) -> Array[String]:
    var validated_extensions = []
    for ext in extensions:
        if ext.strip_edges().trim_prefix(".").is_valid_filename():
            validated_extensions.append(ext)
        else:
            print("Warning: Invalid extension: ", ext)
    return validated_extensions

func get_extensions(extensions_field: LineEdit) -> Array[String]:
    var extensions = extensions_field.text.split(",", false)
    return _validate_extensions(extensions)	

func _on_save_pressed():
    # Save settings to ProjectSettings
    ProjectSettings.set_setting("plugins/character_setup_plugin/api_key", api_key_field.text)
    ProjectSettings.set_setting("plugins/character_setup_plugin/scan_method", scan_method_field.selected)
    
    # Parse and validate extensions
    var image_extensions = get_extensions(image_extensions_field)
    var audio_extensions = get_extensions(audio_extensions_field)

    ProjectSettings.set_setting("plugins/character_setup_plugin/image_extensions", image_extensions)
    ProjectSettings.set_setting("plugins/character_setup_plugin/audio_extensions", audio_extensions)
    
    # Save collision shape type
    var shape_type = ["rectangle", "capsule", "circle"][collision_shape_field.selected]
    ProjectSettings.set_setting("plugins/character_setup_plugin/collision_shape_type", shape_type)
    
	# Save colors
    ProjectSettings.set_setting("plugins/character_setup_plugin/collision_box_color", collision_color_field.color)
    ProjectSettings.set_setting("plugins/character_setup_plugin/hit_box_color", hit_color_field.color)
    ProjectSettings.set_setting("plugins/character_setup_plugin/detection_area_color", area_color_field.color)

	# Save asset map path
    ProjectSettings.set_setting("plugins/character_setup_plugin/asset_map_path", asset_map_path_field.text)

    # Save project settings
    ProjectSettings.save()
    
    print("Character Setup Plugin: Settings saved.")
    
    # Notify plugin to reinitialize
    var plugin = get_node_or_null("/root/EditorNode/CharacterSetupPlugin")
    if plugin:
        plugin.reinitialize_scanner()