func _ready():
    # Test data: Array of [file_path, expected_name]
    var test_cases = [
        ["res://game/levels/Level1.tscn", "Level1"], # All components ignored
        ["res://project/world/Zone1.tscn", "Zone1"], # Non-ignored component
        ["res://assets/scripts/Player.gd", "Player"], # All components ignored
        ["res://gameplay/mechanics/Core.tscn", "Mechanics"], # Partial ignored
        ["res://scene.tscn", "Scene"], # Single component (ignored)
        ["res://root/MyFile.tres", "Root"], # Single non-ignored component
        ["res://", "Root"], # Empty path
    ]
    
    # Run tests
    var detector = NameDetector.new()
    var passed = 0
    var total = test_cases.size()
    
    for test in test_cases:
        var file_path = test[0]
        var expected = test[1]
        var result = detector.determine_name(file_path)
        var is_pass = result == expected
        print("Test: %s -> Expected: %s, Got: %s, %s" % [file_path, expected, result, "PASS" if is_pass else "FAIL"])
        if is_pass:
            passed += 1
    
    # Summary
    print("Tests passed: %d/%d" % [passed, total])        