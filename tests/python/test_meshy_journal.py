import tempfile
import unittest
from dataclasses import replace
from pathlib import Path

from tools.meshy.journal import TaskJournal, TaskRecord


class JournalTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / ".meshy/tasks.json"
        self.journal = TaskJournal(self.path)
        self.record = TaskRecord(
            asset_id="models/wall.glb",
            source_hash="source",
            parameter_hash="params",
            task_id="task-1",
            destination="assets/models/wall.glb",
            state="submitted",
            progress=0,
            credits=None,
            created_at="2026-09-07T10:00:00Z",
            updated_at="2026-09-07T10:00:00Z",
        )

    def tearDown(self):
        self.temp.cleanup()

    def test_atomic_write_reload_and_resume_match(self):
        self.journal.upsert(self.record)
        self.assertTrue(self.path.is_file())
        self.assertFalse(self.path.with_suffix(self.path.suffix + ".tmp").exists())
        loaded = TaskJournal(self.path)
        self.assertEqual(loaded.find_resumable("models/wall.glb", "source", "params"), self.record)
        self.assertIsNone(loaded.find_resumable("models/wall.glb", "other", "params"))
        self.assertIsNone(loaded.find_resumable("models/wall.glb", "source", "other"))

    def test_state_transition_is_persisted(self):
        self.journal.upsert(self.record)
        self.journal.upsert(replace(self.record, state="processing", progress=55))
        loaded = TaskJournal(self.path).find_resumable("models/wall.glb", "source", "params")
        self.assertEqual((loaded.state, loaded.progress), ("processing", 55))

    def test_error_text_is_sanitized(self):
        unsafe = "msy_ABC123 Authorization: Bearer token data:image/png;base64,AAAA https://x.test/file?token=secret&x=1"
        self.journal.upsert(replace(self.record, error=unsafe))
        serialized = self.path.read_text(encoding="utf-8")
        for forbidden in ("msy_", "Bearer ", "data:image/", "token=secret"):
            self.assertNotIn(forbidden, serialized)


if __name__ == "__main__":
    unittest.main()
