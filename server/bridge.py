"""
P-113 Data Bridge Server
Lightweight Flask server that Godot polls for live data.
Runs on the Pi alongside the Godot app.
Fetches weather and status from OpenClaw via Tailscale.
"""

import json
import time
import threading
from datetime import datetime
from flask import Flask, jsonify

app = Flask(__name__)

# Cached data (updated by background thread)
_cache = {
    "weather": {},
    "time": {},
    "status": {"state": "active", "message": ""},
    "last_updated": None,
}
_cache_lock = threading.Lock()

# --- Configuration ---
WEATHER_POLL_INTERVAL = 300  # 5 minutes
OPENCLAW_GATEWAY_URL = "http://100.64.0.1:18789"  # Tailscale IP (update for your setup)


@app.route("/status")
def status():
    """Main endpoint polled by Godot."""
    with _cache_lock:
        data = dict(_cache)
    # Always include fresh time
    now = datetime.now()
    data["time"] = {
        "hour": now.hour,
        "minute": now.minute,
        "day_of_week": now.strftime("%A"),
        "date": now.strftime("%Y-%m-%d"),
        "period": _get_period(now.hour),
    }
    return jsonify(data)


@app.route("/health")
def health():
    return jsonify({"ok": True})


def _get_period(hour: int) -> str:
    if 6 <= hour < 10:
        return "morning"
    elif 10 <= hour < 14:
        return "midday"
    elif 14 <= hour < 17:
        return "afternoon"
    elif 17 <= hour < 21:
        return "evening"
    return "night"


def _fetch_weather():
    """Fetch weather from wttr.in (no API key needed)."""
    import urllib.request
    try:
        url = "https://wttr.in/Chicago?format=j1"
        req = urllib.request.Request(url, headers={"User-Agent": "DeskCompanion/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            current = data.get("current_condition", [{}])[0]
            return {
                "temp_f": current.get("temp_F", ""),
                "temp_c": current.get("temp_C", ""),
                "condition": current.get("weatherDesc", [{}])[0].get("value", "").lower(),
                "humidity": current.get("humidity", ""),
                "wind_mph": current.get("windspeedMiles", ""),
            }
    except Exception as e:
        print(f"[bridge] Weather fetch error: {e}")
        return {}


def _background_updater():
    """Background thread that periodically refreshes cached data."""
    while True:
        try:
            weather = _fetch_weather()
            with _cache_lock:
                if weather:
                    _cache["weather"] = weather
                _cache["last_updated"] = datetime.now().isoformat()
        except Exception as e:
            print(f"[bridge] Update error: {e}")
        time.sleep(WEATHER_POLL_INTERVAL)


if __name__ == "__main__":
    # Start background updater
    updater = threading.Thread(target=_background_updater, daemon=True)
    updater.start()
    # Run Flask (on Pi, bind to localhost only)
    app.run(host="127.0.0.1", port=5113, debug=False)
