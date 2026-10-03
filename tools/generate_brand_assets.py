"""Render PSF SVG masters into transparent, power-of-two WoW TGA textures.

Requires Inkscape CLI and Pillow. No raster source or embedded bitmap is used.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
import subprocess
from PIL import Image

media = Path(__file__).resolve().parents[1] / "PadSkinForever" / "Media"
with TemporaryDirectory(prefix="psf-brand-") as temporary:
    for name, width, height in [("PSFLogo", 256, 128), ("PSFFocusChevron", 32, 64)]:
        png = Path(temporary) / (name + ".png")
        subprocess.run([
            "inkscape", str(media / (name + ".svg")),
            "--export-type=png", "--export-filename=" + str(png),
            "--export-width=" + str(width * 2),
        ], check=True)
        image = Image.open(png).convert("RGBA")
        image.thumbnail((width, height), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (width, height))
        canvas.paste(image, ((width - image.width) // 2, (height - image.height) // 2))
        canvas.save(media / (name + ".tga"), compression=None)
