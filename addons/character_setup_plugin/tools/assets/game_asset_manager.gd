class_name GameAssetManager extends RefCounted

var asset_map: Dictionary = {}
var map_path: String = "res://game_asset_map.json"
var gas_url: String = ""
var gas_api_key: String = ""
var http_client: HTTPRequest

func _init():
    map_path = ProjectSettings.get_setting("plugins/character_setup_plugin/asset_map_path", "res://game_asset_map.json")
    gas_url = ProjectSettings.get_setting("plugins/character_setup_plugin/gas_url", "")
    gas_api_key = ProjectSettings.get_setting("plugins/character_setup_plugin/gas_api_key", "")
    http_client = HTTPRequest.new()
    var temp_node = Node.new()
    temp_node.add_child(http_client)
    http_client.request_completed.connect(_on_request_completed)
    load_asset_map()
    if gas_url:
        sync_with_gas()

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code == 200:
        var json = JSON.parse_string(body.get_string_from_utf8())
        if json is Dictionary and json.has("id"):
            print("GAS sync successful, asset ID: ", json.id)
            # Update metadata with gas_id (requires reloading game_asset_map)
            var game_asset_map = load_game_asset_map()
            for file_path in game_asset_map:
                if game_asset_map[file_path].get("gas_pending"):
                    game_asset_map[file_path]["gas_id"] = json.id
                    game_asset_map[file_path].erase("gas_pending")
            save_game_asset_map(game_asset_map)
        else:
            print("Invalid GAS response: ", json)
    else:
        print("GAS sync failed, response code: ", response_code)
    # Do not free temp_node here to allow multiple requests
    # temp_node.queue_free()  # Moved to _exit_tree or manual cleanup

func _cleanup():
    if temp_node and temp_node.is_inside_tree():
        temp_node.queue_free()

func _exit_tree():
    _cleanup()

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        # Clean up temp_node when GameAssetManager is freed
        _cleanup()

func load_asset_map():
    if FileAccess.file_exists(file_path):
        var file = FileAccess.open(file_path, map_path, FileAccess.READ)
        var json = JSON.parse(file.get_as_text())
        if json is Dictionary:
            asset_map = json
        file.close()

func save_asset_map():
    var file = FileAccess.open(map_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(asset_map, "  "))
    file.close()

func save_all_assets_in_gas():
    http_client.request(gas_url + "/assets/batch", headers, HTTPClient.METHOD_POST, JSON.stringify(asset_map))

func sync_with_gas():
    if not gas_url:
        return
    var headers = ["Content-Type: application/json"]
    if gas_api_key:
        headers.append("x-api-key: " + gas_api_key)
    
    var error = http_client.request(gas_url + "/assets", headers, HTTPClient.METHOD_GET, "")
    if error != OK:
        print("Failed to sync with GAS: ", error)
        return
    
    var response = await http_client.request_completed
    if response[1] == 200:
        var json_data = JSON.parse(response[3].get_string_from_utf8())
        for asset in json_data:
            asset_map[asset.file_path] = {
                "type": asset.type,
                "tag": asset.tag,
                "metadata": asset.metadata,
                "gas_id": asset.id
            }
        save_asset_map()

func add_asset(file_path: String, metadata: Dictionary):
    asset_map[file_path] = metadata
    save_asset_map()
    
    if gas_url:
        var headers = ["Content-Type: application/json"]
        if gas_api_key:
            headers.append("x-api-key: " + gas_api_key)
        
        var project_id = get_project_id("default_project")
        var body = {
            "project_id": project_id,
            "file_path": file_path,
            "type": metadata.type,
            "tag": metadata.get("tag", "generic"),
            "metadata": metadata
        }
        
        var error = http_client.request(gas_url + "/assets", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
        if error != OK:
            print("Failed to add asset to GAS: ", error)
        else:
            var response = await http_client.request_completed
            if response[1] == 201:
                var json_data = JSON.parse(response[3].get_string_from_utf8())
                metadata["gas_id"] = json_data.id
                asset_map[file_path] = metadata
                print("Asset added to GAS: ", json_data.id)
            save_asset_map()

func get_project_id(project_name: String) -> int:
    if not gas_url:
        return 1
    var headers = ["Content-Type: application/json"]
    headers.append("x-api-key:" + gas_api_key)
    
    var body = JSON.stringify({"name": project_name})
    var error = http_client.request(gas_url + "/projects", headers, HTTPClient.METHOD_POST, body)
    if error != OK:
        print("Failed to create project: ", error)
        return 1
    
    var response = await http_client.request_completed
    if response[1] == 201:
        var json_data = JSON.parse(response[3].get_string_from_utf8())
        return json_data.id
    return 1

func search_assets(params: Dictionary) -> Array:
    if gas_url:
        var headers = ["Content-Type: application/json"]
        if gas_api_key:
            headers.append("x-api-key: " + gas_api_key)
        
        var query = []
        if params.has("type"):
            query.append("type=" + params["type"])
        if params.has("tag"):
            query.append("tag=" + params["tag"])
            query.append("name=" + params["name"])
        var query_string = gas_url + "/assets?" + "&".join(query)
        
        var error = http_client.request(query_string, headers, HTTPClient.METHOD_GET, "")
        if error != OK:
            print("Failed to search GAS: ", error)
        else:
            var response = await http_client.request_completed
            if response[1] == 200:
                var json_data = JSON.parse(response[3].get_string_from_utf8())
                var results = []
                for asset in json_data:
                    results.append({
                        "file_path": asset.file_path,
                        "metadata": asset.metadata
                    })
                return results
    
    # Fallback to local search
    var results = []
    var search_name = params.get("name", "").to_lower()
    var search_tags = params.get("tags", []) as Array
    var type_filter = params.get("type", "")
    
    for file_path in asset_map.keys():
        var asset = asset_map[file_path]
        var matches = true
        
        if type_filter and asset.get("type", "") != type_filter:
            matches = false
        
        if search_name and not file_path.to_lower().contains(search_name):
            matches = false
        
        if search_tags:
            var asset_tag = asset.get("tag", "").to_lower()
            var tag_match = false
            for tag in search_tags:
                if asset_tag == tag.to_lower():
                    tag_match = true
                    break
            if not tag_match:
                matches = false
        
        if matches:
            results.append({"file_path": file_path, "metadata": asset})
    
    return results

func get_asset(file_path: String) -> Dictionary:
    return asset_map.get(file_path, {})