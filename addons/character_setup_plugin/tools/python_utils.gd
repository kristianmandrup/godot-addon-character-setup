class_name PythonUtils extends RefCounted

func install_python_dependencies() -> bool:
    var python_path = get_python_path()
    if python_path == "":
        print("Error: Python not found. Please install Python 3.x.")
        return false
    
    var requirements_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/requirements.txt")
    var output = []
    var exit_code = OS.execute(python_path, ["-m", "pip", "install", "-r", requirements_path], output, true)
    
    if exit_code == 0:
        print("Python dependencies installed successfully.")
        return true
    else:
        print("Failed to install dependencies: ", output)
        return false

func get_python_path() -> String:
    var candidates = [
        "python",
        "python3",
        "C:/Python39/python.exe",  # Adjust for your system
        "/usr/bin/python3",
        "/usr/local/bin/python3"
    ]
    for candidate in candidates:
        var output = []
        if OS.execute(candidate, ["-c", "import sys"], output, true) == 0:
            return candidate
    return ""

func check_pip_availability() -> bool:
    var output = []
    var exit_code = OS.execute("python", ["-m", "pip", "--version"], output, true)
    return exit_code == 0

func check_dependencies(imports: String = "") -> bool:
    var output = []
    var exit_code = OS.execute("python", ["-c", "import " + imports], output, true)
    if exit_code != 0:
        print("Error: Python dependencies missing. Run 'pip install -r res://addons/character_setup_plugin/requirements.txt' to install " + imports)
        return false
    return true

func check_opencv_availability() -> bool:
    return check_dependencies("cv2, numpy")

func check_audio_availability() -> bool:
    return check_dependencies("librosa, numpy, tensorflow, tensorflow_hub")
