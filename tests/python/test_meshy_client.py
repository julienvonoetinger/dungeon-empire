import io
import json
import tempfile
import unittest
import urllib.error
from pathlib import Path

from tools.meshy.client import MeshyClient, MeshyError


class FakeResponse:
    def __init__(self, payload: bytes):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self):
        return self.payload


class MeshyClientTests(unittest.TestCase):
    def test_request_encodes_json_and_authorization(self):
        seen = {}

        def opener(request, timeout):
            seen["request"] = request
            seen["timeout"] = timeout
            return FakeResponse(b'{"result":"task-1"}')

        result = MeshyClient("secret-key", opener=opener).request("POST", "https://example.test/tasks", {"x": 1})
        self.assertEqual(result, {"result": "task-1"})
        self.assertEqual(seen["request"].get_header("Authorization"), "Bearer secret-key")
        self.assertEqual(json.loads(seen["request"].data), {"x": 1})

    def test_http_errors_are_classified_and_secret_safe(self):
        def opener(_request, timeout):
            raise urllib.error.HTTPError("https://example.test", 401, "Bearer secret-key", {}, io.BytesIO(b'bad secret-key'))

        with self.assertRaises(MeshyError) as caught:
            MeshyClient("secret-key", opener=opener).request("GET", "https://example.test")
        self.assertEqual(caught.exception.kind, "auth")
        self.assertEqual(caught.exception.status_code, 401)
        self.assertNotIn("secret-key", str(caught.exception))
        self.assertNotIn("Bearer", str(caught.exception))

    def test_invalid_json_is_classified(self):
        client = MeshyClient("key", opener=lambda _request, timeout: FakeResponse(b"not-json"))
        with self.assertRaises(MeshyError) as caught:
            client.request("GET", "https://example.test")
        self.assertEqual(caught.exception.kind, "invalid_response")

    def test_get_task_and_download(self):
        calls = []

        def opener(request, timeout):
            calls.append(request.full_url)
            if request.full_url.endswith("/abc"):
                return FakeResponse(b'{"status":"SUCCEEDED"}')
            return FakeResponse(b"glb-bytes")

        client = MeshyClient("key", opener=opener)
        self.assertEqual(client.get_task("https://example.test/tasks", "abc")["status"], "SUCCEEDED")
        with tempfile.TemporaryDirectory() as folder:
            destination = Path(folder) / "asset.glb"
            client.download("https://example.test/model.glb", destination)
            self.assertEqual(destination.read_bytes(), b"glb-bytes")
        self.assertEqual(len(calls), 2)


if __name__ == "__main__":
    unittest.main()
