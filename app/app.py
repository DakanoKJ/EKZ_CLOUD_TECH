import os

import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")


def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        sslmode="require",
        connect_timeout=5,
    )


@app.route("/")
def index():
    return jsonify(status="ok", message="web-app is running")


@app.route("/health")
def health():
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify(status="ok", db="connected")
    except Exception as exc:
        return jsonify(status="error", db="unavailable", detail=str(exc)), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
