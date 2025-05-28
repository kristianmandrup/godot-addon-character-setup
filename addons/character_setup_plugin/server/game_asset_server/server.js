const express = require("express");
const sqlite3 = require("sqlite3").verbose();
const bodyParser = require("body-parser");
const cors = require("cors");
const path = require("path");
const fs = require("fs");

const app = express();
const port = process.env.PORT || 3000;
const uploadDir = path.join(__dirname, "uploads");
const db = new sqlite3.Database("game_assets.db");

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use("/uploads", express.static(uploadDir));

// Ensure upload directory exists
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Initialize database
db.serialize(() => {
  db.run(`
        CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `);
  db.run(`
        CREATE TABLE IF NOT EXISTS assets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER,
            file_path TEXT NOT NULL,
            type TEXT NOT NULL,
            tag TEXT,
            metadata TEXT,  // JSON string
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (project_id) REFERENCES projects(id)
        )
    `);
});

// API Key Middleware (optional)
const apiKey = process.env.API_KEY || "your-secret-key";
const authenticate = (req, res, next) => {
  const key = req.headers["x-api-key"];
  if (apiKey && key !== apiKey) {
    return res.status(401).json({ error: "Invalid API key" });
  }
  next();
};

// Endpoints
// Create Project
app.post("/projects", authenticate, (req, res) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ error: "Project name required" });
  }
  db.run("INSERT INTO projects (name) VALUES (?)", [name], function (err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.status(201).json({ id: this.lastID, name });
  });
});

// List Projects
app.get("/projects", authenticate, (req, res) => {
  db.all("SELECT * FROM projects", [], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(rows);
  });
});

// Create Asset
app.post("/assets", authenticate, (req, res) => {
  return addAsset(res, body);
});

const addAsset = (res, body) => {
  const { project_id, file_path, type, tag, metadata } = body;
  if (!project_id || !file_path || !type) {
    return res
      .status(400)
      .json({ error: "project_id, file_path, and type required" });
  }
  db.run(
    "INSERT INTO assets (project_id, file_path, type, tag, metadata) VALUES (?, ?, ?, ?, ?)",
    [project_id, file_path, type, tag, JSON.stringify(metadata || {})],
    function (err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.status(201).json({ id: this.lastID, file_path, type, tag, metadata });
    }
  );
};

// Batch Create Asset
app.post("/assets/batch", authenticate, (req, res) => {
  var batch = req.body;
  for (file_path of batch.keys()) {
    var metadata = file_map[file_path];
    var body = { file_path, metadata };
    addAsset(res, body);
  }
});

// List Assets
app.get("/assets", authenticate, (req, res) => {
  const { type, tag, name } = req.query;
  let query = "SELECT * FROM assets WHERE 1=1";
  const params = [];
  if (type) {
    query += " AND type = ?";
    params.push(type);
  }
  if (tag) {
    query += " AND tag = ?";
    params.push(tag);
  }
  if (name) {
    query += " AND file_path LIKE ?";
    params.push(`%${name}%`);
  }
  db.all(query, params, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    rows = rows.map((row) => ({
      ...row,
      metadata: row.metadata ? JSON.parse(row.metadata) : {},
    }));
    res.json(rows);
  });
});

// Get Asset
app.get("/assets/:id", authenticate, (req, res) => {
  db.get("SELECT * FROM assets WHERE id = ?", [req.params.id], (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (!row) {
      return res.status(404).json({ error: "Asset not found" });
    }
    row.metadata = row.metadata ? JSON.parse(row.metadata) : {};
    res.json(row);
  });
});

// Update Asset
app.put("/assets/:id", authenticate, (req, res) => {
  const { file_path, type, tag, metadata } = req.body;
  db.run(
    "UPDATE assets SET file_path = ?, type = ?, tag = ?, metadata = ? WHERE id = ?",
    [file_path, type, tag, JSON.stringify(metadata || {}), req.params.id],
    function (err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: "Asset not found" });
      }
      res.json({ id: req.params.id, file_path, type, tag, metadata });
    }
  );
});

// Delete Asset
app.delete("/assets/:id", authenticate, (req, res) => {
  db.run("DELETE FROM assets WHERE id = ?", [req.params.id], function (err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (this.changes === 0) {
      return res.status(404).json({ error: "Asset not found" });
    }
    res.status(204).send();
  });
});

app.listen(port, () => {
  console.log(`Game Asset Server running on http://localhost:${port}`);
});
