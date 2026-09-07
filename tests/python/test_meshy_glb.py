import json
import struct
import tempfile
import unittest
from pathlib import Path

from tools.meshy.glb import GlbValidationError, install_download, validate_glb


def glb_bytes(document=None, *, magic=b"glTF", version=2, declared_delta=0, truncate=0):
    document = {"asset": {"version": "2.0"}, "meshes": [{}]} if document is None else document
    payload = json.dumps(document, separators=(",", ":")).encode("utf-8")
    payload += b" " * ((4 - len(payload) % 4) % 4)
    chunk = struct.pack("<II", len(payload), 0x4E4F534A) + payload
    total = 12 + len(chunk)
    data = struct.pack("<4sII", magic, version, total + declared_delta) + chunk
    return data[:-truncate] if truncate else data


class FakeClient:
    def __init__(self, payload):
        self.payload = payload

    def download(self, _url, destination):
        destination.write_bytes(self.payload)


class GlbTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def validate_bytes(self, payload):
        path = self.root / "test.glb"
        path.write_bytes(payload)
        return validate_glb(path)

    def test_valid_glb(self):
        info = self.validate_bytes(glb_bytes())
        self.assertEqual((info.version, info.chunk_count, info.has_json, info.has_meshes), (2, 1, True, True))

    def test_malformed_glbs_are_rejected(self):
        cases = [
            glb_bytes(magic=b"nope"),
            glb_bytes(version=1),
            glb_bytes(declared_delta=4),
            struct.pack("<4sII", b"glTF", 2, 12),
            glb_bytes({"asset": {"version": "2.0"}}),
            glb_bytes(truncate=2),
        ]
        for payload in cases:
            with self.subTest(size=len(payload)):
                with self.assertRaises(GlbValidationError):
                    self.validate_bytes(payload)

    def test_malformed_json_is_rejected(self):
        payload = b"{bad" + b" " * 3
        chunk = struct.pack("<II", len(payload), 0x4E4F534A) + payload
        with self.assertRaises(GlbValidationError):
            self.validate_bytes(struct.pack("<4sII", b"glTF", 2, 12 + len(chunk)) + chunk)

    def test_install_is_atomic_and_protects_existing_destination(self):
        destination = self.root / "models/wall.glb"
        destination.parent.mkdir()
        destination.write_bytes(b"existing")
        with self.assertRaises(FileExistsError):
            install_download(FakeClient(glb_bytes()), "https://example.test/model", destination, force=False)
        self.assertEqual(destination.read_bytes(), b"existing")
        info = install_download(FakeClient(glb_bytes()), "https://example.test/model", destination, force=True)
        self.assertTrue(info.has_meshes)
        self.assertEqual(destination.read_bytes()[:4], b"glTF")
        self.assertFalse(destination.with_suffix(destination.suffix + ".download").exists())

    def test_invalid_download_preserves_destination(self):
        destination = self.root / "wall.glb"
        destination.write_bytes(b"existing")
        with self.assertRaises(GlbValidationError):
            install_download(FakeClient(b"broken"), "https://example.test/model", destination, force=True)
        self.assertEqual(destination.read_bytes(), b"existing")
        self.assertFalse(destination.with_suffix(destination.suffix + ".download").exists())


if __name__ == "__main__":
    unittest.main()
