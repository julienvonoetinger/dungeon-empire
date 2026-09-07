import json
import struct
import tempfile
import unittest
from pathlib import Path

from tools.meshy.journal import TaskJournal, TaskRecord
from tools.meshy_pipeline import run


def valid_glb():
    payload = json.dumps({"asset": {"version": "2.0"}, "meshes": [{}]}).encode()
    payload += b" " * ((4 - len(payload) % 4) % 4)
    chunk = struct.pack("<II", len(payload), 0x4E4F534A) + payload
    return struct.pack("<4sII", b"glTF", 2, 12 + len(chunk)) + chunk


class FakeClient:
    def __init__(self, statuses=None):
        self.statuses = list(statuses or [{"status": "SUCCEEDED", "model_urls": {"glb": "https://signed.test/model?token=x"}}])
        self.submissions = 0
        self.polls = 0

    def request(self, method, _url, _body=None):
        self.submissions += 1
        return {"result": "task-1"}

    def get_task(self, _endpoint, _task_id):
        self.polls += 1
        return self.statuses.pop(0)

    def download(self, _url, destination):
        destination.write_bytes(valid_glb())


class PipelineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        source = self.root / "production/meshy_assets/walls/ref.png"
        source.parent.mkdir(parents=True)
        source.write_bytes(b"image")
        manifest = self.root / "production/manifests/meshy_model_manifest.csv"
        manifest.parent.mkdir(parents=True)
        manifest.write_text(
            "mesh_output,strategy,families,source_images\n"
            "models/environment/wall.glb,static_mesh,walls,walls/ref.png\n",
            encoding="utf-8",
        )

    def tearDown(self):
        self.temp.cleanup()

    def test_dry_run_is_networkless_and_writes_nothing(self):
        def forbidden_factory():
            self.fail("dry-run created a Meshy client")

        result = run(["models/environment/wall.glb"], repo_root=self.root, client_factory=forbidden_factory)
        self.assertEqual(result, 0)
        self.assertFalse((self.root / ".meshy/tasks.json").exists())
        self.assertFalse((self.root / "assets/models/environment/wall.glb").exists())

    def test_execute_processes_then_validates_download(self):
        fake = FakeClient([
            {"status": "PROCESSING", "progress": 25},
            {"status": "SUCCEEDED", "progress": 100, "consumed_credits": 20, "model_urls": {"glb": "https://signed.test/model?token=x"}},
        ])
        result = run(["models/environment/wall.glb", "--execute"], repo_root=self.root, client_factory=lambda: fake, sleep_fn=lambda _n: None)
        self.assertEqual(result, 0)
        self.assertEqual(fake.submissions, 1)
        self.assertEqual(fake.polls, 2)
        self.assertEqual((self.root / "assets/models/environment/wall.glb").read_bytes()[:4], b"glTF")
        record = TaskJournal(self.root / ".meshy/tasks.json").records[0]
        self.assertEqual((record.state, record.credits), ("validated", 20))
        self.assertNotIn("token=x", (self.root / ".meshy/tasks.json").read_text())

    def test_resume_does_not_submit_again(self):
        fake = FakeClient()
        source_hash, parameter_hash = self._hashes()
        TaskJournal(self.root / ".meshy/tasks.json").upsert(TaskRecord(
            "models/environment/wall.glb", source_hash, parameter_hash, "existing-task",
            "assets/models/environment/wall.glb", "processing", 40, None, "now", "now",
        ))
        result = run(["walls", "--execute"], repo_root=self.root, client_factory=lambda: fake, sleep_fn=lambda _n: None)
        self.assertEqual(result, 0)
        self.assertEqual(fake.submissions, 0)
        self.assertEqual(fake.polls, 1)

    def test_resubmit_and_terminal_failures(self):
        for terminal in ("FAILED", "CANCELED"):
            with self.subTest(terminal=terminal):
                fake = FakeClient([{"status": terminal, "task_error": {"message": "bad msy_SECRET"}}])
                result = run(["walls", "--execute", "--resubmit"], repo_root=self.root, client_factory=lambda: fake, sleep_fn=lambda _n: None)
                self.assertEqual(result, 1)
                self.assertEqual(fake.submissions, 1)
                self.assertNotIn("msy_", (self.root / ".meshy/tasks.json").read_text())

    def test_existing_destination_requires_force_before_client_creation(self):
        destination = self.root / "assets/models/environment/wall.glb"
        destination.parent.mkdir(parents=True)
        destination.write_bytes(b"existing")
        result = run(["walls", "--execute"], repo_root=self.root, client_factory=lambda: self.fail("client created"))
        self.assertEqual(result, 1)
        self.assertEqual(destination.read_bytes(), b"existing")

    def _hashes(self):
        from tools.meshy_pipeline import hashes_for_job
        from tools.meshy.manifest import load_jobs
        job = load_jobs(self.root, self.root / "production/manifests/meshy_model_manifest.csv")["models/environment/wall.glb"]
        return hashes_for_job(job, 10000, "")


if __name__ == "__main__":
    unittest.main()
