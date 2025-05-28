# Character Setup Plugin for Godot

This plugin provides tools with MCP support to create and manage Godot characters such as the player character, enemies, NPCs, including collision shapes, hitboxes, and detection areas.
A Games Asset Server (GAS) is included which can be used to manage game assets (images, audio, etc.) and sync them between a local mapping file and a remote server with a REST API backed by an SQLite database.

The plugin also includes detection tools for image files and audio files, which can be used to automatically generate collision shapes, hitboxes, and detection areas for sprite sheets.

- ability to analyze audio files with the [YAMNet](https://github.com/tensorflow/models/tree/master/research/audioset/yamnet) model and generate tags for audio files
- ability to analyze image files with the [OpenCV](https://opencv.org/) library and generate collision shapes for sprite sheets
- ability to detect and assign tags to image files

These abilities can be used to further enhance a character by adding matching audio and animations.

## Status

Work In progress... lots of stuff to do. Stay tuned!

## How to use

Configure the MCP server in `~/.cursor/mcp.json` (global) or .`cursor/mcp.json` (project-specific):
json

```json
{
  "mcpServers": {
    "character-setup-mcp": {
      "command": "node",
      "args": ["res://addons/character_setup_plugin/server/index.js"],
      "env": { "MCP_TRANSPORT": "stdio" }
    }
  }
}
```

Add the plugin to your project:

```bash
cd /path/to/your/project
mkdir -p addons
git clone https://github.com/kristianmandrup/character-setup-plugin.git addons/character-setup
```

# Install OpenCV

1. Install [Python 3.x](https://www.python.org/downloads/) Note: Usually your OS comes with Python pre-installed.
2. Ensure Python is in the system `PATH` ie. `python --version` should return `Python 3.x.x`.

# Install Node.js

1. Install [Node.js](https://nodejs.org/en/download/).

## File Detectors

- **ImageDetector**: Detects image files (default: `.png`, `.jpg`, `.jpeg`, `.bmp`) and analyzes sprite sheets using OpenCV.
- **AudioDetector**: Detects audio files (default: `.wav`, `.ogg`, `.mp3`) and assigns tags.
- Configure extensions via code or plugin settings.

## Collision Tools

- **CollisionBox**: Generates physics collision shapes (feet, half height), blue.
- **HitBox**: Generates hitboxes (full sprite), red.
- **DetectionArea**: Generates detection areas (3x collision, circular), green.
- Configure colors in the settings panel.
