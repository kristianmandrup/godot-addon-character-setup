extends Node2D

func _ready():
    var generator = AnimationGenerator.new(GameAssetManager.new(), SpriteTools.new())
    var player = generator.generate_animation_player("Player", "res://sprites/player_sheet.png")
    if player:
        add_child(player)
        var anim_player = player.get_node("AnimationPlayer")
        print("Animations:", anim_player.get_animation_list())