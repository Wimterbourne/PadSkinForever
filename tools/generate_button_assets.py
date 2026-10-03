"""Generate original minimal button artwork; no external dependencies."""
from pathlib import Path
import math, struct
p = Path(__file__).resolve().parents[1] / "PadSkinForever"
# Generate uncompressed RGBA TGA assets, supersampling for smooth thin borders.
media=p/'Media';media.mkdir(exist_ok=True)
for shape in ['Circle','Square']:
    for kind in ['Border','Pressed','Empty']:
        data=bytearray()
        for y in range(64):
            for x in range(64):
                inside=0
                for sy in range(4):
                    for sx in range(4):
                        xx=x+(sx+.5)/4-32; yy=y+(sy+.5)/4-32
                        d=math.hypot(xx,yy) if shape=='Circle' else max(abs(xx),abs(yy))
                        inner = 27 if shape == "Circle" else 28.5
                        if (d<30 if kind=='Empty' else inner<=d<30):inside+=1
                a=round(255*inside/16)
                rgb=(16,20,26) if kind=='Empty' else (255,255,255)
                if kind=='Pressed': a=round(a*.65)
                data.extend((*rgb[::-1],a))
        header=struct.pack('<BBBHHBHHHHBB',0,0,2,0,0,0,0,0,64,64,32,0x28)
        (media/f'{shape}{kind}.tga').write_bytes(header+data)
