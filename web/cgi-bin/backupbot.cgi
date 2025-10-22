#!/usr/bin/env python3
import cgi
import cgitb
import os
import json
import glob

cgitb.enable()
print("Content-Type: application/json\n")

ENV_FILE = "/config/backupbot.env"
ZONEINFO_DIR = "/usr/share/zoneinfo"


def read_env():
    env = {}
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip().split("#")[0].strip()
                env[key] = val
    return env


def write_env(env):
    with open(ENV_FILE, "w") as f:
        for key, val in env.items():
            f.write(f"{key}={val}\n")


def list_timezones():
    zones = []
    for root, _, files in os.walk(ZONEINFO_DIR):
        rel_root = os.path.relpath(root, ZONEINFO_DIR)
        if rel_root.startswith("posix") or rel_root.startswith("right"):
            continue
        for file in files:
            if file.startswith(".") or file.endswith((".tab", ".zi")):
                continue
            zones.append(os.path.join(rel_root, file) if rel_root != "." else file)
    return sorted(zones)


form = cgi.FieldStorage()
action = form.getvalue("action")

if action == "get":
    print(json.dumps(read_env()))
elif action == "set":
    try:
        raw = os.environ.get("CONTENT_LENGTH")
        length = int(raw) if raw else 0
        data = json.loads(os.read(0, length))
        write_env(data)
        print(json.dumps({"status": "ok", "message": "Configuration saved."}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
elif action == "get_timezones":
    print(json.dumps({"timezones": list_timezones()}))
else:
    print(json.dumps({"status": "error", "message": "Invalid action"}))
