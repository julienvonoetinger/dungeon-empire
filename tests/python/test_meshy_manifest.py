import tempfile
import unittest
from pathlib import Path

from tools.meshy.manifest import ManifestError, load_jobs, select_jobs


class ManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "production/meshy_assets/walls").mkdir(parents=True)
        (self.root / "production/meshy_assets/walls/ref.png").write_bytes(b"png")
        (self.root / "production/manifests").mkdir(parents=True)
        self.manifest = self.root / "production/manifests/meshy_model_manifest.csv"

    def tearDown(self):
        self.temp.cleanup()

    def write(self, rows):
        self.manifest.write_text(
            "mesh_output,strategy,families,source_images\n" + "\n".join(rows) + "\n",
            encoding="utf-8",
        )

    def test_valid_row_and_explicit_selection(self):
        self.write(["models/environment/wall.glb,static_mesh,walls,walls/ref.png"])
        jobs = load_jobs(self.root, self.manifest)
        job = jobs["models/environment/wall.glb"]
        self.assertEqual(job.source, (self.root / "production/meshy_assets/walls/ref.png").resolve())
        self.assertEqual(job.destination, (self.root / "assets/models/environment/wall.glb").resolve())
        self.assertEqual(select_jobs(jobs, ["walls"]), [job])
        self.assertEqual(select_jobs(jobs, ["assets/models/environment/wall.glb"]), [job])

    def test_duplicate_identifier_is_rejected(self):
        row = "models/environment/wall.glb,static_mesh,walls,walls/ref.png"
        self.write([row, row])
        with self.assertRaises(ManifestError):
            load_jobs(self.root, self.manifest)

    def test_missing_source_is_rejected(self):
        self.write(["models/environment/wall.glb,static_mesh,walls,walls/missing.png"])
        with self.assertRaises(ManifestError):
            load_jobs(self.root, self.manifest)

    def test_unsafe_destinations_and_2d_rows_are_rejected(self):
        for output, strategy in [
            (str((self.root / "absolute.glb").resolve()), "static_mesh"),
            ("models/../../escape.glb", "static_mesh"),
            ("models/ui/icon.glb", "2d_only_not_for_meshy"),
        ]:
            with self.subTest(output=output, strategy=strategy):
                self.write([f"{output},{strategy},walls,walls/ref.png"])
                with self.assertRaises(ManifestError):
                    load_jobs(self.root, self.manifest)

    def test_selection_must_be_explicit_and_known(self):
        self.write(["models/environment/wall.glb,static_mesh,walls,walls/ref.png"])
        jobs = load_jobs(self.root, self.manifest)
        with self.assertRaisesRegex(ManifestError, "at least one explicit asset selector is required"):
            select_jobs(jobs, [])
        with self.assertRaises(ManifestError):
            select_jobs(jobs, ["unknown"])


if __name__ == "__main__":
    unittest.main()
