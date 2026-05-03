const express = require("express");
const fetch = require("node-fetch");

const app = express();
app.use(express.json());

const API_URL = process.env.API_URL;

// HEALTH
app.get("/health", (req, res) => {
    res.json({ frontend: "UP" });
});

// CREATE
app.post("/api/add", async (req, res) => {
    try {
        const r = await fetch(`${API_URL}/api/tasks`, {
            method: "POST",
            headers: {"Content-Type":"application/json"},
            body: JSON.stringify(req.body)
        });

        const text = await r.text();
        res.status(r.status).send(text);
    } catch {
        res.status(500).json({ error: "Backend unreachable" });
    }
});

// LIST
app.get("/api/list", async (req, res) => {
    try {
        const r = await fetch(`${API_URL}/api/tasks`);
        const text = await r.text();
        res.status(r.status).send(text);
    } catch {
        res.status(500).json({ error: "Backend unreachable" });
    }
});

// DELETE
app.delete("/api/delete/:id", async (req, res) => {
    try {
        const r = await fetch(`${API_URL}/api/tasks/${req.params.id}`, {
            method: "DELETE"
        });

        const text = await r.text();
        res.status(r.status).send(text);
    } catch {
        res.status(500).json({ error: "Delete failed" });
    }
});

// UI
app.get("/", (req, res) => {
    res.send(`
    <h2>CloudOps Dashboard</h2>

    <input id="t" placeholder="Task"/>
    <button onclick="add()">Add</button>
    <button onclick="load()">Refresh</button>

    <ul id="list"></ul>

    <script>
    async function add(){
        const v = document.getElementById("t").value;
        if(!v.trim()) return alert("Enter task");

        await fetch('/api/add',{
            method:'POST',
            headers:{'Content-Type':'application/json'},
            body:JSON.stringify({title:v})
        });

        load();
    }

    async function del(id){
        await fetch('/api/delete/'+id,{ method:'DELETE' });
        load();
    }

    async function load(){
        const r = await fetch('/api/list');
        const data = await r.json();

        const list = document.getElementById("list");
        list.innerHTML = "";

        data.forEach(t=>{
            const li = document.createElement("li");
            li.innerHTML = 
                t.Title + " [" + t.Status + "] " +
                "<button onclick='del("+t.Id+")'>❌</button>";
            list.appendChild(li);
        });
    }

    load();
    </script>
    `);
});

// START
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("Frontend running"));