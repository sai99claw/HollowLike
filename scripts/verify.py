"""Run game regressions with one disposable player profile per test suite."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', shutil.which('godot') or 'godot'))
parser.add_argument('--pack', type=Path)
parser.add_argument('tests', nargs='*')
args = parser.parse_args()
tests = [ROOT / 'tests' / value for value in args.tests] if args.tests else sorted((ROOT / 'tests').glob('test_*.gd'))
failures = []
for test in tests:
    command = [args.godot, '--headless', '--path', str(ROOT)]
    if args.pack:
        command += ['--main-pack', str(args.pack.resolve())]
    command += ['--script', str(test)]
    with tempfile.TemporaryDirectory(prefix='pigeon-test-') as profile:
        environment = dict(os.environ, XDG_DATA_HOME=profile)
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=180, env=environment)
            output = result.stdout + result.stderr
            passed = result.returncode == 0 and 'SCRIPT ERROR' not in output and 'ERROR:' not in output
        except subprocess.TimeoutExpired:
            output, passed = 'Test exceeded its suite timeout', False
    print(('PASS ' if passed else 'FAIL ') + test.name, flush=True)
    if not passed:
        failures.append(test.name)
        print(output[-6000:], flush=True)
print(f'{len(tests)-len(failures)}/{len(tests)} suites passed', flush=True)
raise SystemExit(bool(failures))
