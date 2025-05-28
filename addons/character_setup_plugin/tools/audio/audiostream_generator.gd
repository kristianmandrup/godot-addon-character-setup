class_name AudioStreamGenerator extends RefCounted

var asset_manager: GameAssetManager

func _init(_asset_manager: GameAssetManager):
    asset_manager = _asset_manager

func generate_audio_stream_player(character_name: String) -> AudioStreamPlayer2D:
    var search_results = asset_manager.search_assets({"name": "character_name", "type": "audio", "tags": ["audio"]})
    if search_results.is_empty():
        print("Error: No audio found for character: ", character_name)
        return null
    
    var audio_path = search_results[0].file_path
    var audio_stream = AudioStreamPlayer2D.new()
    audio_stream.name = "AudioStreamPlayer"
    audio_stream.audio_stream = ResourceLoader.load(audio_path) as AudioStream
    audio_stream.autoplay = true
    return audio_stream