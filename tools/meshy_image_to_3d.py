#!/usr/bin/env python3
"""Create a Meshy Image-to-3D task and save a GLB into assets/models/.

Usage:
  python tools/meshy_image_to_3d.py path/to/ref.png --out assets/models/core.glb
  python tools/meshy_image_to_3d.py --url https://.../ref.png --out assets/models/door.glb
  python tools/meshy_image_to_3d.py --ping
"""
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = "https://api.meshy.ai/openapi/v1/image-to-3d"


def load_env() -> None:
    env_path = ROOT / ".env"
    if not env_path.is_file():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, val = line.split("=", 1)
        os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))


def headers() -> dict:
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        sys.exit("MESHY_API_KEY missing. Put it in .env (see .env.example).")
    return {
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
    }


def api(method: str, url: str, body: dict | None = None) -> dict:
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers(), method=method)
    try:
        with urllib.request.urlopen(req, timeout=180) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        sys.exit("Meshy HTTP %s: %s" % (e.code, err[:800]))


def ping() -> None:
    payload = api("GET", API + "?page_size=1")
    print("Meshy API: ok")
    if isinstance(payload, dict):
        keys = list(payload.keys())
        print("list keys:", keys[:8])


def image_to_data_uri(path: Path) -> str:
    mime = mimetypes.guess_type(path.name)[0] or "image/png"
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    return "data:%s;base64,%s" % (mime, b64)


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=120) as resp:
        dest.write_bytes(resp.read())


def main() -> None:
    load_env()
    p = argparse.ArgumentParser()
    p.add_argument("image", nargs="?", help="Local PNG/JPG to send as a data URI")
    p.add_argument("--url", help="Public image URL instead of a local file")
    p.add_argument("--out", default="assets/models/meshy_out.glb")
    p.add_argument("--ping", action="store_true")
    p.add_argument("--polycount", type=int, default=10000)
    p.add_argument("--texture-prompt", default="")
    args = p.parse_args()
    if args.ping:
        ping()
        return
    if not args.image and not args.url:
        sys.exit("Pass an image path or --url (or --ping).")
    image_url = args.url if args.url else image_to_data_uri(Path(args.image))
    body = {
        "image_url": image_url,
        "model_type": "smart-topology",
        "ai_model": "meshy-t2",
        "target_polycount": args.polycount,
        "should_texture": True,
        "enable_pbr": True,
        "target_formats": ["glb"],
        "origin_at": "bottom",
    }
    if args.texture_prompt:
        body["texture_prompt"] = args.texture_prompt
    created = api("POST", API, body)
    task_id = created.get("result")
    if not task_id:
        sys.exit("No task id: %s" % created)
    print("task", task_id)
    while True:
        task = api("GET", "%s/%s" % (API, task_id))
        status = str(task.get("status", ""))
        print("status", status, "progress", task.get("progress"))
        if status == "SUCCEEDED":
            glb = (task.get("model_urls") or {}).get("glb")
            if not glb:
                sys.exit("Succeeded but no glb url: %s" % task)
            dest = ROOT / args.out
            download(glb, dest)
            print("saved", dest)
            return
        if status == "FAILED":
            err = task.get("task_error") or {}
            sys.exit("Failed: %s" % err)
        time.sleep(5)


if __name__ == "__main__":
    main()
