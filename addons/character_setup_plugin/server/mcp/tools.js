const tools = [
  {
    name: "scan_filesystem",
    description:
      "Scan the project filesystem for changes and update the file map",
    execute: async (params) => {
      const {
        incremental = true,
        ignore_patterns = [".godot", ".import"],
        root_path = "res://",
      } = params;
      const result = await godotCall("scan_project_files", {
        incremental,
        ignore_patterns,
        root_path,
      });
      return result;
    },
  },
  {
    name: "get_file_map",
    description: "Retrieve the current file map",
    execute: async () => {
      const file_map = await godotCall("load_file_map", {});
      return file_map;
    },
  },
  {
    name: "create_character_scene",
    description: "Create a new character scene with a CharacterBody2D root",
    execute: async (params) => {
      // Use Godot CLI or editor API to create a scene
      // Return scene path or success message
    },
  },
  {
    name: "assign_sprite",
    description: "Assign a sprite image to a Sprite2D node in a scene",
    execute: async (params) => {
      const { scene_path, node_name, sprite_tag } = params;
      // Read file map, filter by sprite_tag (e.g., "character")
      // Use Godot editor API to assign texture to Sprite2D node
    },
  },
  {
    name: "add_collision_shape",
    description: "Add a collision shape to a node based on a sprite",
    execute: async (params) => {
      const { scene_path, node_name, sprite_path } = params;
      // Call Godot to generate and add collision shape
    },
  },

  {
    name: "analyze_sprite_sheet",
    description:
      "Analyze a sprite sheet to count sprites, detect grid, and generate collision shapes",
    execute: async (params) => {
      const { image_path } = params;
      const result = await godotCall("analyze_sprite_local", { image_path });
      return result;
    },
  },
  {
    name: "add_collision_shape_advanced",
    description: "Add a collision shape to a node based on sprite analysis",
    execute: async (params) => {
      const { scene_path, node_name, image_path } = params;
      const analysis = await godotCall("analyze_sprite_local", { image_path });
      if (analysis.collision_shapes && analysis.collision_shapes.size() > 0) {
        await godotCall("add_collision_shape", {
          scene_path,
          node_name,
          collision_points: analysis.collision_shapes[0],
        });
        return { status: "Collision shape added" };
      }
      return { error: "No collision shapes found" };
    },
  },
];
