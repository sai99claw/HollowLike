"""Build the bundled Chinese font from UI strings AND decoded asset metadata."""
from pathlib import Path
import argparse,json
from fontTools.ttLib import TTFont
from fontTools import subset
ROOT=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser();parser.add_argument('full_font',type=Path,nargs='?');parser.add_argument('--check',action='store_true',help='Verify the bundled font against current UI strings without rebuilding');args=parser.parse_args()
target=ROOT/'assets/Chinese.otf'
previous=TTFont(target);codes=set(previous.getBestCmap());previous.close()
def collect(value):
    if isinstance(value,str):codes.update(map(ord,value))
    elif isinstance(value,dict):
        for key,item in value.items():collect(key);collect(item)
    elif isinstance(value,list):
        for item in value:collect(item)
for path in (ROOT/'scripts').glob('*.gd'):collect(path.read_text(encoding='utf-8'))
for path in (ROOT/'assets').rglob('*.json'):collect(json.loads(path.read_text(encoding='utf-8')))
if args.check:
    bundled=TTFont(target);available=set(bundled.getBestCmap());bundled.close()
    missing=sorted(chr(code) for code in codes-available if 0x3400<=code<=0x9fff)
    assert not missing, f'Missing UI glyphs; rebuild subset_font.py from Noto CJK: {missing}'
    print('Bundled font check passed: every Chinese UI and metadata character is available')
    raise SystemExit(0)
if args.full_font is None:parser.error('full_font is required unless --check is used')
font=TTFont(args.full_font);available=set(font.getBestCmap());options=subset.Options();options.layout_features=['*'];options.name_IDs=['*']
builder=subset.Subsetter(options=options);builder.populate(unicodes=codes);builder.subset(font);font.save(target);font.close()
missing=sorted(chr(code) for code in codes-available if 0x3400<=code<=0x9fff)
assert not missing, f'Unsupported Chinese characters: {missing}'
print(f'Bundled font updated: {len(codes & available)} glyphs, zero missing Chinese characters')
