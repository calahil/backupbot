#!/usr/bin/env python3
import cgi
import cgitb
import os
import json
import sys
import traceback
import tempfile

cgitb.enable()
print("Content-Type: application/json\n")

ENV_FILE = "/config/backupbot.conf"
ZONEINFO_DIR = "/usr/share/zoneinfo"

# Logging level from environment
LOG_LEVEL = os.environ.get("BACKUPBOT_WEB_LOGGING", "info").lower()
LOG_LEVELS = {"debug": 3, "info": 2, "warn": 1}


def log(level, message, exc=None):
    """
    Docker-friendly logging.
    level: "debug", "info", "warn"
    exc: exception object (only used in debug)
    """
    if LOG_LEVELS.get(level, 0) <= LOG_LEVELS.get(LOG_LEVEL, 0):
        timestamp = (
            __import__("datetime")
            .datetime.now()
            .strftime(
                "%Y-%m-%d \
                                                                    %H:%M:%S"
            )
        )
        msg = f"[{timestamp}] [{level.upper()}] {message}"
        print(msg, file=sys.stderr)
        if exc and LOG_LEVEL == "debug":
            traceback.print_exception(
                type(exc), exc, exc.__traceback__, file=sys.stderr
            )


def read_env():
    env = {}
    if os.path.exists(ENV_FILE):
        try:
            with open(ENV_FILE) as f:
                for line in f:
                    line = line.strip()
                    if not line or "=" not in line:
                        continue
                    key, val = line.split("=", 1)
                    env[key.strip()] = val.strip()
        except Exception as e:
            log("warn", f"Failed to read config: {e}", e)
    return env


def write_env(env):
    try:
        dir_name = os.path.dirname(ENV_FILE)
        os.makedirs(dir_name, exist_ok=True)
        # Write atomically to temp file
        with tempfile.NamedTemporaryFile("w", dir=dir_name, delete=False) as tmp:
            for key, val in env.items():
                tmp.write(f"{key}={val}\n")
            temp_name = tmp.name
        os.replace(temp_name, ENV_FILE)
        log("info", f"Configuration saved to {ENV_FILE}")
    except Exception as e:
        log("warn", f"Failed to write config: {e}", e)
        raise


def list_timezones():
    zones = []
    for root, _, files in os.walk(ZONEINFO_DIR):
        rel_root = os.path.relpath(root, ZONEINFO_DIR)
        if rel_root.startswith(("posix", "right")):
            continue
        for file in files:
            if file.startswith(".") or file.endswith((".tab", ".zi")):
                continue
            zones.append(os.path.join(rel_root, file) if rel_root != "." else file)
    return sorted(zones)


form = cgi.FieldStorage()
action = form.getvalue("action")

try:
    if action == "get":
        env = read_env()
        log("debug", f"Returning configuration: {env}")
        print(json.dumps(env))
    elif action == "set":
        raw_len = os.environ.get("CONTENT_LENGTH")
        length = int(raw_len) if raw_len else 0
        data = json.loads(os.read(0, length))
        log("debug", f"Received new configuration: {data}")
        env = read_env()
        env.update(data)  # update existing keys, add new keys
        write_env(env)
        print(json.dumps({"status": "ok", "message": "Configuration saved."}))
    elif action == "get_timezones":
        zones = list_timezones()
        log("debug", f"Returning {len(zones)} timezones")
        print(json.dumps({"timezones": zones}))
    else:
        log("warn", f"Invalid action requested: {action}")
        print(json.dumps({"status": "error", "message": "Invalid action"}))
except Exception as e:
    log("warn", f"Unhandled exception: {e}", e)
    print(json.dumps({"status": "error", "message": str(e)}))
