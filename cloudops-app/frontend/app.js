const express = require("express");
const fetch = require("node-fetch");

const app = express();
app.use(express.json());

const API_URL = process.env.API_URL;

// ✅ Health
app.get("/health", (req, res) => {
    res.json({ frontend: "UP" });
});

// ✅ Add task (with error handling)
app.post("/api/add", async (req, res) => {
    try {
        const r = await fetch(`${API_URL}/api/tasks`, {
            method: "POST",
            headers: {"Content-Type":"application/json"},
            body: JSON.stringify(req.body)
        });

        if (!r.ok) {
            const text = await r.text();
            return res.status(500).json({ error: "Backend error", details: text });
        }

        res.json(await r.json());
    } catch (err) {
        console.error("Frontend Add Error:", err);
        res.status(500).json({ error: "Unable to reach backend" });
    }
});

// ✅ List tasks (with error handling)
app.get("/api/list", async (req, res) => {
    try {
        const r = await fetch(`${API_URL}/api/tasks`);

        if (!r.ok) {
            const text = await r.text();
            return res.status(500).json({ error: "Backend error", details: text });
        }

        res.json(await r.json());
    } catch (err) {
        console.error("Frontend List Error:", err);
        res.status(500).json({ error: "Unable to reach backend" });
    }
});

// ✅ UI (slightly improved for visibility)
app.get("/", (req, res) => {
    res.send(`
        <h2>CloudOps Dashboard</h2>
        <input id="t" placeholder="Enter task"/>
        <button onclick="add()">Add</button>
        <button onclick="load()">Refresh</button>
        <pre id="out"></pre>

        <script>
        async function add(){
            const v = document.getElementById("t").value;

            const r = await fetch('/api/add',{
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body:JSON.stringify({title:v})
            });

            const data = await r.json();
            document.getElementById("out").innerText =
                JSON.stringify(data,null,2);

            load();
        }

        async function load(){
            const r = await fetch('/api/list');
            const data = await r.json();

            document.getElementById("out").innerText =
                JSON.stringify(data,null,2);
        }
        </script>
    `);
});

// ✅ PORT (App Service compatibility)
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Frontend running on ${PORT}`));