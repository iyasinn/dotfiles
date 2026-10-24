"""Bound optional GIF input before handing it to WezTerm's native decoder.

This cannot catch decoder or BlobLease failures inside WezTerm. Native graphics
remain opt-in; file errors here must never prevent session navigation.
"""
import base64
from functools import lru_cache
from pathlib import Path


MAX_BYTES = 2 * 1024 * 1024
MAX_PIXELS = 1024 * 1024


@lru_cache(maxsize=1)
def image_payload(filename):
    # Keep one bounded copy for this picker process. No temporary image files,
    # downloads, or writes to WezTerm's internal cache.
    if not filename:
        return None
    try:
        path = Path(filename)
        if not path.is_file() or path.stat().st_size > MAX_BYTES:
            return None
        with path.open("rb") as source:
            data = source.read(MAX_BYTES + 1)
    except OSError:
        return None
    if len(data) < 14 or len(data) > MAX_BYTES:
        return None
    if data[:6] not in (b"GIF87a", b"GIF89a") or data[-1:] != b";":
        return None
    width = int.from_bytes(data[6:8], "little")
    height = int.from_bytes(data[8:10], "little")
    if not width or not height or width * height > MAX_PIXELS:
        return None
    # Header checks are resource guards, not full GIF validation.
    return base64.b64encode(data).decode("ascii")
