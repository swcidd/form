#!/usr/bin/env python3
"""Generate FORM's launcher icon and splash mark.

Run from the repository root:

    python3 tool/generate_brand_assets.py

The mark is typographic rather than illustrative: "+1" set in Barlow Condensed
Bold, the same face the app's display sizes use. It says what the app is for -
beat yourself by one - and it is a font the app already ships, so there is no
third-party artwork here to license.

Outputs, all checked in so a build never depends on this script having run:

    assets/branding/app_icon.png             1024x1024, ink ground, lime mark
    assets/branding/app_icon_foreground.png  1024x1024, transparent, for the
                                             Android adaptive icon safe zone
    assets/branding/splash_logo.png          transparent, ink mark for the
                                             cream splash screen
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "branding"
FONT = ROOT / "assets" / "fonts" / "BarlowCondensed-Bold.ttf"

# Straight from lib/theme/app_colors.dart so the mark cannot drift from the app.
INK = (0x12, 0x15, 0x12, 255)
LIME = (0xD5, 0xFC, 0x61, 255)
CREAM = (0xFA, 0xFA, 0xF7, 255)
TRANSPARENT = (0, 0, 0, 0)

SIZE = 1024
MARK = "+1"


def render_mark(colour: tuple[int, int, int, int], height: int) -> Image.Image:
    """The mark alone, cropped to its own ink, in the given colour."""
    if not FONT.exists():
        sys.exit(
            f"{FONT.relative_to(ROOT)} is missing - the brand mark is set in a "
            "font this repository ships, so generate the fonts first."
        )

    # Start large and measure, so the crop is tight whatever the face's
    # metrics are rather than relying on a guessed pixel size.
    font = ImageFont.truetype(str(FONT), SIZE)
    canvas = Image.new("RGBA", (SIZE * 2, SIZE * 2), TRANSPARENT)
    draw = ImageDraw.Draw(canvas)
    draw.text((SIZE // 2, SIZE // 2), MARK, font=font, fill=colour)

    ink = canvas.getbbox()
    if ink is None:
        sys.exit("the mark rendered empty")

    cropped = canvas.crop(ink)
    scale = height / cropped.height
    return cropped.resize(
        (max(1, round(cropped.width * scale)), height), Image.LANCZOS
    )


def centred(mark: Image.Image, size: int, background: tuple[int, int, int, int]):
    canvas = Image.new("RGBA", (size, size), background)
    canvas.alpha_composite(
        mark, ((size - mark.width) // 2, (size - mark.height) // 2)
    )
    return canvas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # Full-bleed icon: ink ground, lime mark filling most of the canvas. Still
    # inside the circle the launchers crop to, with room for the corner radius
    # a square mask takes off.
    icon = centred(render_mark(LIME, int(SIZE * 0.60)), SIZE, INK)
    icon.convert("RGB").save(OUT / "app_icon.png")

    # Adaptive icon foreground: Android masks this to roughly the middle two
    # thirds, so the mark is smaller and the canvas transparent.
    centred(render_mark(LIME, int(SIZE * 0.42)), SIZE, TRANSPARENT).save(
        OUT / "app_icon_foreground.png"
    )

    # Splash: ink mark on the cream the app's own backgrounds use, so the
    # hand-off to the first frame is a fade rather than a flash.
    centred(render_mark(INK, int(SIZE * 0.34)), SIZE, TRANSPARENT).save(
        OUT / "splash_logo.png"
    )

    for name in ("app_icon.png", "app_icon_foreground.png", "splash_logo.png"):
        path = OUT / name
        with Image.open(path) as image:
            print(f"{path.relative_to(ROOT)}  {image.size[0]}x{image.size[1]}  {image.mode}")


if __name__ == "__main__":
    main()
