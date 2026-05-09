from pathlib import Path
from PIL import Image

ROOT = Path('/home/ubuntu/mercurio_mobile_app')
SOURCE = Path('/home/ubuntu/webdev-static-assets/mercurio-icon.png')
TARGETS = [
    ROOT / 'assets/images/icon.png',
    ROOT / 'assets/images/splash-icon.png',
    ROOT / 'assets/images/favicon.png',
    ROOT / 'assets/images/android-icon-foreground.png',
]

with Image.open(SOURCE) as img:
    img = img.convert('RGBA').resize((512, 512), Image.Resampling.LANCZOS)
    for target in TARGETS:
        target.parent.mkdir(parents=True, exist_ok=True)
        img.save(target, format='PNG', optimize=True, compress_level=9)
        print(f'{target}: {target.stat().st_size / 1024:.1f}KB')
