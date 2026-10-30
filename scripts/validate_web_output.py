"""Validate release chunks and remove only interrupted export/copy temporaries."""
from pathlib import Path
import hashlib
import json
from release_budget import validate_budget

ROOT = Path(__file__).resolve().parent.parent
output = ROOT / 'dist'
if (output / 'client').is_dir():output = output / 'client'
for pattern in ('.game-*.bin.*', '.engine-*.bin.*', '.index.*'):
    for path in output.glob(pattern):
        path.unlink()
for name in ('pck-parts.json', 'wasm-parts.json'):
    manifest = json.loads((output / name).read_text())
    digest = hashlib.sha256()
    total = 0
    for part in manifest['parts']:
        path = output / part
        assert path.parent == output and path.is_file(), part
        data = path.read_bytes()
        assert len(data) < 16*1024*1024, part
        digest.update(data)
        total += len(data)
    assert total == manifest['size'] and digest.hexdigest() == manifest['sha256'], name
expanded = validate_budget(ROOT/'dist')
print(f'Final hosting output verified: {expanded} bytes; chunk hashes match')
