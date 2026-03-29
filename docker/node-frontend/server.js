const express = require("express");
const axios = require("axios");

const app = express();
const PORT = 3000;
const API_URL = process.env.API_URL || "http://python-api:5000";

app.get("/", (req, res) => {
  res.json({ message: "DevOps Platform Frontend", status: "running" });
});

app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

app.get("/api/backend-info", async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/api/info`);
    res.json({ frontend: "node-app", backend: response.data });
  } catch (error) {
    res.status(500).json({ error: "Backend API unreachable" });
  }
});

app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});
