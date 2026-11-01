"""Export outside the checkout, test the pack, then copy finalized host assets."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from release_budget import validate_budget

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', shutil.which('godot') or 'godot'))
parser.add_argument('--tests', nargs='+', help='Run only these suites; default is the full release regression set')
parser.add_argument('--data-home', help='XDG data home containing godot/export_templates/4.7.2.stable')
args = parser.parse_args()
environment = os.environ.copy()
if args.data_home:
    environment['XDG_DATA_HOME'] = str(Path(args.data_home).resolve())
with tempfile.TemporaryDirectory(prefix='pigeon-web-export-') as directory:
    output = Path(directory)
    result = subprocess.run([args.godot, '--headless', '--path', str(ROOT), '--export-release', 'Web', str(output/'index.html')], capture_output=True, text=True, env=environment)
    if result.returncode or 'ERROR:' in result.stdout + result.stderr:
        print(result.stdout + result.stderr)
        raise SystemExit(1)
    subprocess.run([sys.executable, str(ROOT/'scripts/verify.py'), '--godot', args.godot, '--pack', str(output/'index.pck')] + (args.tests or ['test_v08.gd', 'test_controls_v07.gd', 'test_v09.gd', 'test_v10.gd', 'test_monster_v10.gd', 'test_v11.gd', 'test_v12.gd', 'test_v13.gd', 'test_v14.gd', 'test_tower_v15.gd', 'test_v16.gd', 'test_v17.gd', 'test_v18.gd', 'test_monster_motion_v18.gd', 'test_v19.gd', 'test_v20.gd', 'test_routes_v20.gd', 'test_v21.gd', 'test_v22.gd', 'test_v23.gd', 'test_v24.gd', 'test_texture_lifetime_v25.gd', 'test_equipment_navigation_v25.gd', 'test_projectile_readability_v25.gd', 'test_stations_v26.gd', 'test_v27.gd', 'test_performance_v28.gd', 'test_heavy_landing_v28.gd', 'test_features_v29.gd', 'test_v30.gd', 'test_projectile_animation_v31.gd', 'test_depth_layout_v32.gd', 'test_home_springs_v33.gd', 'test_fountain_placement_v33.gd', 'test_grounded_art_v34.gd', 'test_boss_director_v35.gd', 'test_review_input_economy.gd', 'test_review_ui_v35.gd', 'test_save_recovery_v35.gd', 'test_display_hd_v36.gd', 'test_monster_roster_v36.gd', 'test_monster_art_v36.gd', 'test_ram_reach_v36.gd', 'test_gameplay_v37.gd', 'test_hit_art_v37.gd', 'test_combat_v38.gd', 'test_combat_v39.gd']), check=True, env=environment)
    subprocess.run([sys.executable, str(ROOT/'scripts/prepare_web.py'), '--directory', str(output)], check=True)
    for name in ['pck-parts.json', 'wasm-parts.json']:
        manifest = json.loads((output/name).read_text())
        data = b''.join((output/part).read_bytes() for part in manifest['parts'])
        assert len(data) == manifest['size']
        assert hashlib.sha256(data).hexdigest() == manifest['sha256']
    # Check the finished candidate, including Worker/manifest allowance, before
    # touching the last successful build. Stale chunks and interrupted copies
    # never enter this newly exported directory.
    validate_budget(output, [ROOT/'server/index.js', ROOT/'.openai/hosting.json'])
    target = ROOT/'dist'
    with tempfile.TemporaryDirectory(prefix='pigeon-host-stage-', dir=ROOT.parent) as staging:
        staged = Path(staging)/'candidate'
        previous = Path(staging)/'previous'
        shutil.copytree(output, staged, ignore=shutil.ignore_patterns('.*'))
        validate_budget(staged, [ROOT/'server/index.js', ROOT/'.openai/hosting.json'])
        if target.exists():target.rename(previous)
        try:
            staged.rename(target)
        except OSError:
            if previous.exists():previous.rename(target)
            raise
print('Web export, packed-resource regressions and chunk hashes passed')
