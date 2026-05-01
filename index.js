const express = require("express");
const sqlite3 = require("sqlite3").verbose();

const app = express();
app.use(express.json());

const db = new sqlite3.Database("./tasks.db");

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    completed INTEGER DEFAULT 0
  )`);
});

// CREATE
app.post("/tasks", (req, res) => {
  const { title } = req.body;
  db.run("INSERT INTO tasks(title) VALUES(?)", [title], function (err) {
    if (err) return res.status(500).json(err);
    res.json({ id: this.lastID, title });
  });
});

// READ
app.get("/tasks", (req, res) => {
  db.all("SELECT * FROM tasks", [], (err, rows) => {
    if (err) return res.status(500).json(err);
    res.json(rows);
  });
});

// UPDATE
app.put("/tasks/:id", (req, res) => {
  db.run(
    "UPDATE tasks SET completed=1 WHERE id=?",
    [req.params.id],
    function (err) {
      if (err) return res.status(500).json(err);
      res.json({ message: "Updated" });
    },
  );
});

// DELETE
app.delete("/tasks/:id", (req, res) => {
  db.run("DELETE FROM tasks WHERE id=?", [req.params.id], function (err) {
    if (err) return res.status(500).json(err);
    res.json({ message: "Deleted" });
  });
});

app.listen(3000, () => {
  console.log("Server running on port 3000");
});
