"""Small Meshy HTTP client with typed, secret-safe failures."""
from __future__ import annotations

import json
import re
import socket
import urllib.error
import urllib.request
from pathlib import Path
from typing import Callable


class MeshyError(RuntimeError):
    def __init__(self, kind: str, message: str, status_code: int | None = None):
        super().__init__(message)
        self.kind = kind
        self.status_code = status_code


class MeshyClient:
    def __init__(
        self,
        api_key: str,
        opener: Callable = urllib.request.urlopen,
        request_timeout: int = 180,
        download_timeout: int = 120,
    ):
        self.api_key = api_key.strip()
        self.opener = opener
        self.request_timeout = request_timeout
        self.download_timeout = download_timeout

    def request(self, method: str, url: str, body: dict | None = None) -> dict:
        data = None if body is None else json.dumps(body, separators=(",", ":")).encode("utf-8")
        request = urllib.request.Request(
            url,
            data=data,
            headers={"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"},
            method=method,
        )
        try:
            with self.opener(request, timeout=self.request_timeout) as response:
                raw = response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            kind = "auth" if error.code in (401, 403) else "rate_limit" if error.code == 429 else "http"
            raise MeshyError(kind, self._sanitize(f"Meshy HTTP {error.code}: {detail[:800]}"), error.code) from None
        except (TimeoutError, socket.timeout) as error:
            raise MeshyError("timeout", self._sanitize(f"Meshy request timed out: {error}")) from None
        except urllib.error.URLError as error:
            kind = "timeout" if isinstance(error.reason, (TimeoutError, socket.timeout)) else "network"
            raise MeshyError(kind, self._sanitize(f"Meshy network failure: {error.reason}")) from None
        except OSError as error:
            raise MeshyError("network", self._sanitize(f"Meshy transport failure: {error}")) from None
        if not raw:
            return {}
        try:
            payload = json.loads(raw)
        except (json.JSONDecodeError, UnicodeDecodeError) as error:
            raise MeshyError("invalid_response", self._sanitize(f"Meshy returned invalid JSON: {error}")) from None
        if not isinstance(payload, dict):
            raise MeshyError("invalid_response", "Meshy response must be a JSON object")
        return payload

    def get_task(self, endpoint: str, task_id: str) -> dict:
        return self.request("GET", f"{endpoint.rstrip('/')}/{task_id}")

    def download(self, url: str, destination: Path) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        request = urllib.request.Request(url)
        try:
            with self.opener(request, timeout=self.download_timeout) as response:
                destination.write_bytes(response.read())
        except (TimeoutError, socket.timeout) as error:
            raise MeshyError("timeout", self._sanitize(f"Meshy download timed out: {error}")) from None
        except (urllib.error.URLError, OSError) as error:
            raise MeshyError("network", self._sanitize(f"Meshy download failed: {error}")) from None

    def _sanitize(self, message: str) -> str:
        sanitized = message.replace(self.api_key, "[REDACTED]") if self.api_key else message
        return re.sub(r"Bearer\s+\S+", "[REDACTED]", sanitized, flags=re.IGNORECASE)
