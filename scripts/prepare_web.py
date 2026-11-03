"""Package Godot's engine and resource pack into static assets below 16 MiB."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent / 'dist'
CHUNK = 14 * 1024 * 1024

def split_file(path: Path, prefix: str, manifest_name: str) -> None:
    if not path.exists():
        assert (ROOT / manifest_name).exists(), f'Export {path.name} first'
        return
    raw = path.read_bytes()
    names = []
    for n, offset in enumerate(range(0, len(raw), CHUNK)):
        name = f'{prefix}-{n}.bin'
        (ROOT / name).write_bytes(raw[offset:offset + CHUNK])
        names.append(name)
    (ROOT / manifest_name).write_text(json.dumps({
        'size': len(raw), 'parts': names, 'sha256': hashlib.sha256(raw).hexdigest()
    }))
    path.unlink()
    # Delete only obsolete chunks produced by this script for the same prefix.
    for old in ROOT.glob(f'{prefix}-*.bin'):
        if old.name not in names:
            old.unlink()
    print(f'Prepared {path.name}: {len(names)} parts, {len(raw)} bytes')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', type=Path, default=ROOT)
    ROOT = parser.parse_args().directory.resolve()
    split_file(ROOT / 'index.wasm', 'engine', 'wasm-parts.json')
    split_file(ROOT / 'index.pck', 'game', 'pck-parts.json')
    import shutil
    shutil.copy2(Path(__file__).resolve().parent.parent / 'web_touch_v29.js', ROOT / 'web_touch_v29.js')
    shutil.copy2(Path(__file__).resolve().parent.parent / 'web_feedback_v30.js', ROOT / 'web_feedback_v30.js')

    shutil.copy2(Path(__file__).resolve().parent.parent / "web_performance_v42.js", ROOT / "web_performance_v42.js")
