const express = require("express");
const sql = require("mssql");

const app = express();
app.use(express.json());

// 🔑 ENV VARIABLES
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

// ✅ CONNECTION POOL
const pool = new sql.ConnectionPool(dbConfig);
const poolConnect = pool.connect();

// ✅ Health
app.get("/health", (req, res) => {
    res.json({ backend: "UP" });
});

// ✅ DB Health
app.get("/health/db", async (req, res) => {
    try {
        await poolConnect;
        await pool.request().query("SELECT 1");
        res.json({ db: "UP" });
    } catch (err) {
        console.error("DB Health Error:", err);
        res.status(500).json({ db: "DOWN" });
    }
});

// ✅ Create task
app.post("/api/tasks", async (req, res) => {
    try {
        const { title } = req.body;

        await poolConnect;
        await pool.request()
            .input("title", sql.NVarChar, title)
            .query("INSERT INTO Tasks (Title) VALUES (@title)");

        res.json({ status: "CREATED" });
    } catch (err) {
        console.error("Create Task Error:", err);
        res.status(500).json({ error: "FAILED TO CREATE TASK" });
    }
});

// ✅ Get tasks
app.get("/api/tasks", async (req, res) => {
    try {
        await poolConnect;
        const result = await pool.request()
            .query("SELECT TOP 20 * FROM Tasks ORDER BY CreatedAt DESC");

        res.json(result.recordset);
    } catch (err) {
        console.error("Fetch Task Error:", err);
        res.status(500).json({ error: "FAILED TO FETCH TASKS" });
    }
});

// ✅ PORT FIX (important)
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on ${PORT}`));