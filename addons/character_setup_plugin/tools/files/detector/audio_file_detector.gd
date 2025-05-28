class_name AudioFileDetector extends BaseFileTypeDetector

var tag_inferer: TagInferer
var extensions: Array[String] = [".wav", ".ogg", ".mp3"]
var asset_manager: GameAssetManager
var audio_analyzer: AudioAnalyzer

func _init(_tag_inferer: TagInferer, _extensions: Array[String]):
    tag_inferer = _tag_inferer
    extensions = _extensions || extensions
    asset_manager = _asset_manager if _asset_manager else GameAssetManager.new()
    audio_analyzer = AudioAnalyzer.new()

func detect(file_path: String, file_name: String) -> Dictionary:
    for ext in extensions:
        if file_name.ends_with(ext):
            return analyze_audio(file_path)
    return {}

func analyze_audio(file_path: String) -> Dictionary:
    var analysis = audio_analyzer.analyze_audio(file_path)
    var tags = analysis.get("tags", [])
    var tag = tags[0].label if tags else tag_inferer.infer_tag(file_path)
    var metadata = {
        "type": "audio",
        "tag": tag,
        "last_modified": analysis.get("last_modified", FileAccess.get_modified_time(file_path)),
        "duration": analysis.get("duration", 0.0),
        "file_size": analysis.get("file_size", 0),
        "sample_rate": analysis.get("sample_rate", 44100),
        "channels": analysis.get("channels", 1),
        "tags": tags
    }
    return metadata