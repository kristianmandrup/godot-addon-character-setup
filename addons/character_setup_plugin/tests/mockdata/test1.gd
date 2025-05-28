func _ready():
    var asset_manager = GameAssetManager.new()
    var sprite_analyzer = SpriteAnalyzer.new()
    var anim_generator = AnimationGenerator.new(asset_manager, sprite_analyzer)
    
    var player = anim_generator.generate_animation_player("Player", "res://sprites/player_character.png")
    if player:
        add_child(player)
        print("Animations: ", player.get_node("AnimationPlayer").get_animation_list())
    
    var audio = anim_generator.generate_audio_stream_player("Player")
    if audio:
        add_child(audio)
        print("Audio: ", audio.stream.resource_path)