#!/usr/bin/env python3
"""Create a Meshy Image-to-Image task and save the PNG.

Usage:
  python tools/meshy_image_to_image.py --prompt "..." --out out.png ref_a.png ref_b.png
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = "https://api.meshy.ai/openapi/v1/image-to-image"

# Reuse helpers from the 3D client.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from meshy_image_to_3d import api, download, image_to_data_uri, load_env  # noqa: E402


def main() -> None:
    load_env()
    p = argparse.ArgumentParser()
    p.add_argument("images", nargs="+", help="1–5 local PNG/JPG references")
    p.add_argument("--prompt", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--model", default="nano-banana-2")
    p.add_argument("--aspect", default="1:1")
    args = p.parse_args()
    if not (1 <= len(args.images) <= 5):
        sys.exit("Need 1 to 5 reference images.")
    refs = []
    for raw in args.images:
        path = Path(raw)
        if not path.is_file():
            path = ROOT / raw
        if not path.is_file():
            sys.exit("Missing image: %s" % raw)
        refs.append(image_to_data_uri(path))
        print("ref", path.name, "bytes", path.stat().st_size)
    created = api(
        "POST",
        API,
        {
            "ai_model": args.model,
            "prompt": args.prompt,
            "reference_image_urls": refs,
            "aspect_ratio": args.aspect,
        },
    )
    task_id = created.get("result")
    if not task_id:
        sys.exit("No task id: %s" % created)
    print("task", task_id)
    while True:
        task = api("GET", "%s/%s" % (API, task_id))
        status = str(task.get("status", ""))
        print("status", status, "progress", task.get("progress"))
        if status == "SUCCEEDED":
            urls = task.get("image_urls") or []
            if not urls:
                sys.exit("Succeeded but no image_urls: %s" % json.dumps(task)[:500])
            dest = Path(args.out)
            if not dest.is_absolute():
                dest = ROOT / dest
            download(urls[0], dest)
            print("saved", dest, "credits", task.get("consumed_credits"))
            return
        if status in ("FAILED", "CANCELED"):
            sys.exit("Failed: %s" % (task.get("task_error") or task))
        time.sleep(2)


if __name__ == "__main__":
    main()
