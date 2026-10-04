"""Generate the PSF resource fill mask (Pillow, no external artwork)."""
from pathlib import Path
from PIL import Image, ImageDraw

scale = 4
image = Image.new("RGBA", (512 * scale, 64 * scale), (255, 255, 255, 0))
ImageDraw.Draw(image).rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius=32 * scale, fill=(255, 255, 255, 255))
image = image.resize((512, 64), Image.Resampling.LANCZOS)
image.save(Path(__file__).resolve().parents[1] / "PadSkinForever/Media/ResourceFillMask.tga", compression=None)
