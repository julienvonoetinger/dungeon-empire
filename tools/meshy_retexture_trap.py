"""Retexture an approved Meshy trap, retaining geometry and resumable task id."""
import argparse
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.meshy_pipeline import make_client
from tools.meshy.glb import install_download

API = "https://api.meshy.ai/openapi/v1/retexture"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    prompt = ("Stylized dark fantasy paving made of broad plain cool blue-gray anthracite stone. "
              "Matte smooth large stone faces, subtle worn bevels, sparse fine natural cracks. "
              "Six existing spike tips are dark forged iron. Stone is undecorated: absolutely no "
              "circles, studs, rivets, dots, embossed shapes, runes or repeating patterns. "
              "Faint deep violet only within natural joints. Preserve the existing geometry.")
    record_path = ROOT / ".meshy/spike_retexture.json"
    output = ROOT / "assets/models/traps/stone_v2/spike_armed_refined.glb"
    if not args.execute:
        print(prompt)
        return
    if output.exists():
        print("Already installed:", output)
        return
    client = make_client()
    if record_path.exists():
        record = json.loads(record_path.read_text())
    else:
        result = client.request("POST", API, {
            "input_task_id": "01a081d0-746f-777c-970c-65edd12fa967",
            "text_style_prompt": prompt, "enable_original_uv": True,
            "enable_pbr": True, "ai_model": "meshy-6",
        })
        record = {"task_id": result["result"], "prompt": prompt}
        record_path.write_text(json.dumps(record, indent=2))
    print("Retexture task:", record["task_id"], flush=True)
    while True:
        task = client.get_task(API, record["task_id"])
        print(task.get("status"), task.get("progress"), flush=True)
        if task["status"] == "SUCCEEDED":
            install_download(client, task["model_urls"]["glb"], output, False)
            record.update(state="validated", credits=task.get("consumed_credits"))
            record_path.write_text(json.dumps(record, indent=2))
            print("Validated:", output)
            return
        if task["status"] in ("FAILED", "CANCELED"):
            raise RuntimeError("Meshy retexture failed")
        time.sleep(5)

if __name__ == "__main__":
    main()
