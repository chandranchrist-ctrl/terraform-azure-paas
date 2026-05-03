const express = require("express");
const sql = require("mssql");

const app = express();
app.use(express.json());

// DB CONFIG
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true,
        trustServerCertificate: false
    }
};

// CONNECTION
let pool;
async function getPool() {
    if (!pool) {
        pool = await sql.connect(dbConfig);
    }
    return pool;
}

// HEALTH
app.get("/health", (req, res) => {
    res.json({ backend: "UP" });
});

// DB HEALTH
app.get("/health/db", async (req, res) => {
    try {
        const pool = await getPool();
        await pool.request().query("SELECT 1");
        res.json({ db: "UP" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ db: "DOWN" });
    }
});

// CREATE → directly Completed
app.post("/api/tasks", async (req, res) => {
    try {
        const { title } = req.body;

        if (!title || !title.trim()) {
            return res.status(400).json({ error: "Title required" });
        }

        const pool = await getPool();

        await pool.request()
            .input("title", sql.NVarChar, title)
            .query(`
                INSERT INTO Tasks (Title, Status)
                VALUES (@title, 'Completed')
            `);

        res.json({ status: "CREATED_COMPLETED" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// GET
app.get("/api/tasks", async (req, res) => {
    try {
		console.log("GET /api/tasks called");
		
        const pool = await getPool();

        const result = await pool.request()
            .query("SELECT TOP 20 * FROM Tasks ORDER BY CreatedAt DESC");

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE
app.delete("/api/tasks/:id", async (req, res) => {
    try {
        const pool = await getPool();

        await pool.request()
            .input("id", sql.Int, req.params.id)
            .query("DELETE FROM Tasks WHERE Id=@id");

        res.json({ status: "DELETED" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// START
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("Backend running"));