"""Original 8px rounded legend corners, supersampled RGBA TGA. No dependencies."""
from pathlib import Path
import math
import struct
media = Path(__file__).resolve().parents[1] / 'PadSkinForever' / 'Media'
media.mkdir(exist_ok=True)
for kind in ('Fill', 'Border'):
    pixels = bytearray()
    for y in range(32):
        for x in range(32):
            coverage = 0
            for sy in range(4):
                for sx in range(4):
                    dx = (x + (sx + .5) / 4) / 4 - 8
                    dy = (y + (sy + .5) / 4) / 4 - 8
                    radius = math.hypot(dx, dy)
                    coverage += radius <= 8 if kind == 'Fill' else 7 <= radius <= 8
            pixels.extend((255, 255, 255, round(255 * coverage / 16)))
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, 32, 32, 32, 0x28)
    (media / f'LegendCorner{kind}.tga').write_bytes(header + pixels)
