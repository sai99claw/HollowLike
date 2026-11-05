"""Package Godot's engine and resource pack into static assets below 16 MiB."""
from pathlib import Path
import gzip
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent / 'dist'
CHUNK = 14 * 1024 * 1024

def split_file(path: Path, prefix: str, manifest_name: str, compress: bool = False) -> None:
    if not path.exists():
        assert (ROOT / manifest_name).exists(), f'Export {path.name} first'
        return
    source = path.read_bytes()
    raw = gzip.compress(source, compresslevel=6, mtime=0) if compress else source
    names = []
    for n, offset in enumerate(range(0, len(raw), CHUNK)):
        name = f'{prefix}-{n}.bin'
        (ROOT / name).write_bytes(raw[offset:offset + CHUNK])
        names.append(name)
    (ROOT / manifest_name).write_text(json.dumps({
        'size': len(raw), 'parts': names, 'sha256': hashlib.sha256(raw).hexdigest(),
        **({'encoding': 'gzip', 'decoded_size': len(source), 'decoded_sha256': hashlib.sha256(source).hexdigest()} if compress else {})
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
    split_file(ROOT / 'index.wasm', 'engine', 'wasm-parts.json', compress=True)
    split_file(ROOT / 'index.pck', 'game', 'pck-parts.json')
    import shutil
    shutil.copy2(Path(__file__).resolve().parent.parent / 'web_touch_v29.js', ROOT / 'web_touch_v29.js')
    shutil.copy2(Path(__file__).resolve().parent.parent / 'web_feedback_v30.js', ROOT / 'web_feedback_v30.js')

    shutil.copy2(Path(__file__).resolve().parent.parent / "web_performance_v42.js", ROOT / "web_performance_v42.js")
