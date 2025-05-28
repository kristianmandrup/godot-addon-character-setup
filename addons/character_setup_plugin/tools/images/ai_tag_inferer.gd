class_name AITagInferer extends TagInferer

var api_key: String

func _init(_api_key: String = ""):
    api_key = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", _api_key)
    if api_key == "":
        print("Warning: No OpenAI API key provided or configured in settings.")

func infer_tag(file_path: String) -> String:
    if file_path.ends_with(".png") or file_path.ends_with(".jpg"):
        var analysis = analyze_image_with_api(file_path)
        return analysis.get("tag", "generic")
    return super.infer_tag(file_path)

func analyze_image_with_api(image_path: String) -> Dictionary:
    if api_key == "":
        print("Error: No API key available for AITagDetector.")
        return {"tag": "generic"}
    
    var http_request = HTTPRequest.new()
    var node = Node.new()
    node.add_child(http_request)
    http_request.request_completed.connect(func(_result, _response_code, _headers, _body): node.queue_free())
    
    var base64_image = image_to_base64(image_path)
    var headers = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
    var body = JSON.stringify({
        "model": "gpt-4o",
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "Analyze this image and suggest a tag (e.g., character, ui, environment) based on its content. Format the response as 'Suggested tag: <tag>'."
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": "data:image/png;base64," + base64_image}
                    }
                ]
            }
        ]
    })
    
    var error = http_request.request("https://api.openai.com/v1/chat/completions", headers, HTTPClient.METHOD_POST, body)
    if error != OK:
        print("API request failed: ", error)
        return {"tag": "generic"}
    
    var response = await http_request.request_completed
    if response[1] == 200:
        var json = JSON.parse_string(response[3].get_string_from_utf8())
        var content = json.choices[0].message.content
        
        var regex = RegEx.new()
        regex.compile("Suggested tag: (\\w+)")
        var regex_match = regex.search(content)
        if regex_match:
            return {"tag": regex_match.get_string(1)}
        return {"tag": "generic"}
    return {"tag": "generic"}

func image_to_base64(image_path: String) -> String:
    var image = Image.load_from_file(image_path)
    var buffer = image.save_png_to_buffer()
    return Marshalls.raw_to_base64(buffer)