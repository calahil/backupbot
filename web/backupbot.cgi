#!/usr/bin/env python3
import cgi
import cgitb
import os
import json

cgitb.enable()
print("Content-Type: application/json\n")

ENV_FILE = "/config/web/backupbot.env"


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
                val = val.strip().split("#")[0].strip()  # strip inline comments
                env[key] = val
    return env


def write_env(env):
    with open(ENV_FILE, "w") as f:
        for key, val in env.items():
            f.write(f"{key}={val}\n")


form = cgi.FieldStorage()
action = form.getvalue("action")

if action == "get":
    env = read_env()
    print(json.dumps(env))
elif action == "set":
    try:
        raw = os.environ.get("CONTENT_LENGTH")
        length = int(raw) if raw else 0
        data = json.loads(os.read(0, length))
        write_env(data)
        print(json.dumps({"status": "ok", "message": "Configuration saved."}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
else:
    print(json.dumps({"status": "error", "message": "Invalid action"}))
