"""Hosting limits checked before a completed export replaces the last build."""
from pathlib import Path

TOTAL_LIMIT = 256 * 1024 * 1024 - 4096
FILE_LIMIT = 16 * 1024 * 1024


def validate_budget(directory: Path, extra_files=()) -> int:
    files = [path for path in directory.rglob('*') if path.is_file()]
    files += [Path(path) for path in extra_files]
    oversized = [f'{path.name}: {path.stat().st_size}' for path in files if path.stat().st_size >= FILE_LIMIT]
    if oversized:
        raise ValueError('Hosting file limit (16 MiB): ' + ', '.join(oversized))
    total = sum(path.stat().st_size for path in files)
    if total >= TOTAL_LIMIT:
        largest = sorted(files, key=lambda path: path.stat().st_size, reverse=True)[:5]
        details = ', '.join(f'{path.name}={path.stat().st_size}' for path in largest)
        raise ValueError(f'Hosting output {total} bytes exceeds 256 MiB; largest files: {details}. Previous build preserved.')
    headroom = TOTAL_LIMIT - total
    print(f'Hosting budget: {total} bytes; {headroom} bytes available')
    if headroom < 8 * 1024 * 1024:
        print('Hosting budget is tight: check the next export before adding more runtime assets.')
    return total
