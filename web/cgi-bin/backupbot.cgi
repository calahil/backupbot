#!/usr/bin/env python3
import cgi
import cgitb
import os
import json
from pathlib import Path

cgitb.enable()

ENV_FILE = Path("/config/backupbot.env")
print("Content-Type: application/json\n")


def read_env():
    env = {}
    if ENV_FILE.exists():
        with ENV_FILE.open() as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, val = line.split("=", 1)
                env[key.strip()] = val.strip().split("#")[0].strip()
    return env


def write_env(env):
    # Rotate the old env file just in case
    if ENV_FILE.exists():
        ENV_FILE.replace(ENV_FILE.with_suffix(".env.bak"))
    with ENV_FILE.open("w") as f:
        for key, val in env.items():
            f.write(f"{key}={val}\n")


form = cgi.FieldStorage()
action = form.getvalue("action")

try:
    if action == "get":
        print(json.dumps(read_env()))
    elif action == "set":
        length = int(os.environ.get("CONTENT_LENGTH", "0"))
        data = json.loads(os.read(0, length))
        write_env(data)
        print(json.dumps({"status": "ok", "message": "Configuration saved."}))
    else:
        print(json.dumps({"status": "error", "message": "Invalid action"}))
except Exception as e:
    print(json.dumps({"status": "error", "message": str(e)}))
