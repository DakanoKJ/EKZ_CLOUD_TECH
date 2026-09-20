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


FULL_NAME = "Полтавский Марк Эдуардович"
FAVORITE_ICE_CREAM = "фисташка-шоколад"


@app.route("/")
def index():
    return f"""
    <html>
      <head><title>web-app</title></head>
      <body style="font-family: sans-serif; padding: 2rem;">
        <h1>web-app is running</h1>
        <p><b>ФИО:</b> {FULL_NAME}</p>
        <p><b>Любимый вкус мороженого:</b> {FAVORITE_ICE_CREAM}</p>
      </body>
    </html>
    """


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
