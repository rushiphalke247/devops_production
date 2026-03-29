from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({"message": "Welcome to DevOps Platform API", "status": "running"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"})

@app.route("/api/info")
def info():
    return jsonify({
        "app": "python-api",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "development")
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
