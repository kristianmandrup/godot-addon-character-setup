# Game Asset Server

This is a simple Node.js server that provides a REST API for managing game assets.

```bash
game-asset-server/
├── server.js              # Node.js server script
├── package.json           # Node.js dependencies
├── game_assets.db         # SQLite database
├── uploads/               # Uploaded asset files
└── README.md              # Server setup instructions
```

## Quickstart

- Run `npm install` to install dependencies.
- Set environment variables (optional):
  - `PORT`: Server port (default: 3000).
  - `API_KEY`: API key for authentication (default: 'your-secret-key').
- Run `npm start` to start the server.
- Access at [localhost:3000](http://localhost:3000)

## API Endpoints

- **POST /projects**: Create a project (`{ "name": "MyGame" }`).
- **GET /projects**: List projects.
- **POST /assets**: Add an asset (`{ "project_id": 1, "file_path": "res://sprites/player.png", "type": "sprite", "tag": "character", "metadata": {} }`).
- **GET /assets**: List assets (query: `?type=sprite&tag=character&name=player`).
- **GET /assets/:id**: Get an asset.
- **PUT /assets/:id**: Update an asset.
- **DELETE /assets/:id**: Delete an asset.

## Deployment

- Local: `npm start`.
- Online: Deploy to Heroku/Render with SQLite file hosted on the server.

## Usage

1. Run `node server.js` to start the server.
2. Open http://localhost:3000 in your browser.
3. Use the API endpoints to manage game assets.

## Database

The server uses a SQLite database to store asset metadata.

### Schema

```sql
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER,
    file_path TEXT NOT NULL,
    type TEXT NOT NULL,
    tag TEXT,
    metadata TEXT,  -- JSON string
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id)
);
```

### API

#### Create Project

POST /projects

Parameters:

- name (string): Project name.

Response:

- id (integer): Project ID.
- name (string): Project name.

#### List Projects

GET /projects

Response:

- id (integer): Project ID.
- name (string): Project name.

#### Create Asset

POST /assets

Parameters:

- project_id (integer): Project ID.
- file_path (string): Asset file path.
- type (string): Asset type (e.g., "sprite", "audio").
- tag (string): Asset tag (e.g., "character", "ui").
- metadata (object): Asset metadata.

Response:

- id (integer): Asset ID.
- file_path (string): Asset file path.
- type (string): Asset type.
- tag (string): Asset tag.
- metadata (object): Asset metadata.

#### List Assets

GET /assets

Query Parameters:

- type (string): Asset type (e.g., "sprite", "audio").
- tag (string): Asset tag (e.g., "character", "ui").
- name (string): Asset file path (partial match).

Response:

- id (integer): Asset ID.
- file_path (string): Asset file path.
- type (string): Asset type.
- tag (string): Asset tag.
- metadata (object): Asset metadata.

#### Get Asset

GET /assets/:id

Response:

- id (integer): Asset ID.
- file_path (string): Asset file path.
- type (string): Asset type.
- tag (string): Asset tag.
- metadata (object): Asset metadata.

#### Update Asset

PUT /assets/:id

Parameters:

- file_path (string): Asset file path.
- type (string): Asset type.
- tag (string): Asset tag.
- metadata (object): Asset metadata.

Response:

- id (integer): Asset ID.
- file_path (string): Asset file path.
- type (string): Asset type.
- tag (string): Asset tag.
- metadata (object): Asset metadata.

#### Delete Asset

DELETE /assets/:id

Response:

- id (integer): Asset ID.
- file_path (string): Asset file path.
- type (string): Asset type.
- tag (string): Asset tag.
- metadata (object): Asset metadata.
