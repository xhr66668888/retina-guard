#!/usr/bin/env python3
"""Render the Android logomark to a multi-resolution Windows .ico file."""
import os
from PIL import Image, ImageDraw

RED = (230, 0, 0, 255)
WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

# Path from android/app/src/main/res/drawable/ic_launcher_foreground.xml
# viewBox is 108x108; circle center (54,54) radius 26.
CX, CY, R = 54.0, 54.0, 26.0


def cubic(p0, p1, p2, p3, n=80):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0]
        y = u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]
        pts.append((x, y))
    return pts


def cutout_path():
    # Reproduces the SVG sub-path that draws the white "speech-mark" cutout.
    # Original commands (relative cubic 'c' then absolute cubic 'C'):
    #   M54,72 c-5.5,0 -10.4,-2.6 -13.6,-6.5
    #          c2.7,-3.4 4.6,-7.4 5.4,-11.7
    #          c1.6,1.4 3.7,2.2 6,2.2
    #          c5,0 9,-4 9,-9
    #          c0,-2.4 -0.9,-4.6 -2.4,-6.2
    #          c1,-0.2 2.1,-0.3 3.2,-0.3
    #          c4.6,0 8.7,1.9 11.7,5
    #          C72.1,55.6 78.1,72 54,72  (absolute)
    cur = (54.0, 72.0)
    rel_segs = [
        ((-5.5, 0), (-10.4, -2.6), (-13.6, -6.5)),
        ((2.7, -3.4), (4.6, -7.4), (5.4, -11.7)),
        ((1.6, 1.4), (3.7, 2.2), (6, 2.2)),
        ((5, 0), (9, -4), (9, -9)),
        ((0, -2.4), (-0.9, -4.6), (-2.4, -6.2)),
        ((1, -0.2), (2.1, -0.3), (3.2, -0.3)),
        ((4.6, 0), (8.7, 1.9), (11.7, 5)),
    ]
    pts = [cur]
    for c1, c2, end in rel_segs:
        p1 = (cur[0] + c1[0], cur[1] + c1[1])
        p2 = (cur[0] + c2[0], cur[1] + c2[1])
        p3 = (cur[0] + end[0], cur[1] + end[1])
        pts.extend(cubic(cur, p1, p2, p3)[1:])
        cur = p3
    # final absolute cubic to (54, 72)
    p1 = (72.1, 55.6)
    p2 = (78.1, 72.0)
    p3 = (54.0, 72.0)
    pts.extend(cubic(cur, p1, p2, p3)[1:])
    return pts


def render(size: int) -> Image.Image:
    """Render the icon at a given size with 4x supersampling."""
    ss = 4
    big = size * ss
    img = Image.new("RGBA", (big, big), TRANSPARENT)
    d = ImageDraw.Draw(img)
    s = big / 108.0  # scale factor

    # Red disk filling almost the whole icon (margin ~2px in 108 viewport)
    margin = 2.0
    d.ellipse(
        [margin * s, margin * s, (108 - margin) * s, (108 - margin) * s],
        fill=RED,
    )

    # White speech-mark cutout
    pts = [(x * s, y * s) for x, y in cutout_path()]
    d.polygon(pts, fill=WHITE)

    return img.resize((size, size), Image.LANCZOS)


def write_ico(images, path):
    """Write a Windows .ico containing every image in `images`.

    PIL's ICO writer would resample everything from a single source image, which
    blurs small sizes. We render each size with supersampling and pack them into
    the .ico container directly.
    """
    import io
    import struct

    entries = []  # (width, height, data)
    for im in images:
        buf = io.BytesIO()
        im.save(buf, format="PNG")
        data = buf.getvalue()
        w = im.size[0] if im.size[0] < 256 else 0
        h = im.size[1] if im.size[1] < 256 else 0
        entries.append((w, h, data))

    out = io.BytesIO()
    out.write(struct.pack("<HHH", 0, 1, len(entries)))  # ICONDIR
    offset = 6 + 16 * len(entries)
    for w, h, data in entries:
        out.write(struct.pack("<BBBBHHII", w, h, 0, 0, 1, 32, len(data), offset))
        offset += len(data)
    for _, _, data in entries:
        out.write(data)
    with open(path, "wb") as f:
        f.write(out.getvalue())


def main():
    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = [render(s) for s in sizes]
    out = os.path.join(os.path.dirname(__file__), "retina-guard.ico")
    write_ico(images, out)
    # Also dump a 256x256 PNG for previewing.
    images[-1].save(os.path.join(os.path.dirname(__file__), "retina-guard.png"))
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
