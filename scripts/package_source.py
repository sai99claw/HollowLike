"""Reproducible complete source archive, delivered separately from the Site."""
from pathlib import Path
import zipfile
ROOT = Path(__file__).resolve().parent.parent / "dist"

project = Path(__file__).resolve().parent.parent
archive = project.parent / 'output/pigeon-tower-source-v07.zip'
archive.parent.mkdir(parents=True, exist_ok=True)
excluded = {'.git', '.godot', '.openai', 'dist', 'exports', '__pycache__'}
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as output:
    for path in sorted(project.rglob('*')):
        rel = path.relative_to(project)
        if not path.is_file() or excluded.intersection(rel.parts) or path.suffix in {'.log', '.tmp'}:
            continue
        info = zipfile.ZipInfo(str(Path('pigeon-tower') / rel), date_time=(2026, 10, 22, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        output.writestr(info, path.read_bytes())
# The downloadable full project is delivered separately to keep the hosted
# source repository below its single-push size limit.
old = ROOT / 'pigeon-tower-source.zip'
if old.exists():
    old.unlink()
print(f'Full project: {archive}, {archive.stat().st_size} bytes')
