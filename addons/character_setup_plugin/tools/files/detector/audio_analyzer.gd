class_name AudioAnalyzer extends RefCounted

func analyze_audio(file_path: String) -> Dictionary:
    # Try Python-based analysis with librosa and YAMNet
    var python_result = analyze_with_python(file_path)
    if not python_result.get("error"):
        return python_result

    # Fallback to Godot-based analysis
    print("Python analysis failed: ", python_result.get("error", "Unknown error"))
    return analyze_with_godot(file_path)

func analyze_with_python(file_path: String) -> Dictionary:
    var python_path = PythonUtils.get_python_path()
    if not python_path:
        return {"error": "Python not found"}

    # Install dependencies if needed
    if not PythonUtils.check_audio_availability():
        PythonUtils.install_python_dependencies()

    var script_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/scripts/audio_analyzer.py")
    var absolute_file_path = ProjectSettings.globalize_path(file_path)

    var output = []
    var exit_code = OS.execute(python_path, [script_path, absolute_file_path], output, true)

    if exit_code == 0 and output.size() > 0:
        var json = JSON.parse_string(output[0])
        if json is Dictionary and not json.has("error"):
            return json
        return {"error": json.get("error", "Invalid JSON output")}
    return {"error": "Python script failed: " + str(output)}

func analyze_with_godot(file_path: String) -> Dictionary:
    var audio_stream = ResourceLoader.load(file_path) as AudioStream
    if not audio_stream:
        print("Error: Failed to load audio file: ", file_path)
        return {}

    var duration = audio_stream.get_length() if audio_stream else 0.0
    var file = FileAccess.open(file_path, FileAccess.READ)
    var file_size = file.get_length() if file else 0
    file.close()

    return {
        "duration": duration,
        "file_size": file_size,
        "sample_rate": 44100,  # Default; Godot doesn't expose this directly
        "channels": 1,  # Assume mono; Godot doesn't expose this
        "last_modified": FileAccess.get_modified_time(file_path),
        "tags": []  # No tags in fallback mode
    }

