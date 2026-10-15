#!/usr/bin/env python3
"""Vellux OS gorsel varlik uretici (yalnizca Python standart kutuphanesi).

Uretilenler:
  plymouth/logo.png      Acilis ekrani logosu (parlayan halka + V isareti)
  plymouth/bar_fill.png  Ilerleme cubugu dolgusu
  plymouth/bar_bg.png    Ilerleme cubugu zemini
  calamares/logo.png     Kurulum sihirbazi logosu
  calamares/welcome.png  Karsilama gorseli

Kullanim: gen-assets.py <cikti_dizini>
"""
import math
import os
import struct
import sys
import zlib


def write_png(path, width, height, pixels):
    """pixels: bytearray RGBA, satir satir."""
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride:(y + 1) * stride])

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(png)


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    cx, cy = ax + t * dx, ay + t * dy
    return math.hypot(px - cx, py - cy)


def lerp(a, b, t):
    return a + (b - a) * t


def smooth(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def over(dst, src):
    """Premultiplied olmayan RGBA 'over' birlestirme (0..1)."""
    sr, sg, sb, sa = src
    dr, dg, db, da = dst
    oa = sa + da * (1 - sa)
    if oa <= 0:
        return (0.0, 0.0, 0.0, 0.0)
    r = (sr * sa + dr * da * (1 - sa)) / oa
    g = (sg * sa + dg * da * (1 - sa)) / oa
    b = (sb * sa + db * da * (1 - sa)) / oa
    return (r, g, b, oa)


def render_logo(size):
    s = size
    c = s / 2.0
    scale = s / 256.0
    pixels = bytearray(s * s * 4)
    ring_r = 100 * scale
    ring_w = 3.2 * scale
    v_w = 9.5 * scale
    a1 = (c - 40 * scale, c - 42 * scale)
    a2 = (c, c + 48 * scale)
    a3 = (c + 40 * scale, c - 42 * scale)
    for y in range(s):
        for x in range(s):
            px, py = x + 0.5, y + 0.5
            col = (0.0, 0.0, 0.0, 0.0)
            d = math.hypot(px - c, py - c)

            # Yumusak dis hale
            glow = math.exp(-((d - ring_r) ** 2) / (2 * (16 * scale) ** 2)) * 0.45
            t = (px + py) / (2.0 * s)
            gr, gg, gb = lerp(0.39, 0.22, t), lerp(0.40, 0.74, t), lerp(0.95, 0.97, t)
            col = over(col, (gr, gg, gb, glow))

            # Gradyan halka
            ring = 1.0 - smooth(ring_w - 1.0, ring_w + 1.0, abs(d - ring_r))
            if ring > 0:
                col = over(col, (gr, gg, gb, ring * 0.95))

            # Ic parlama
            inner = math.exp(-(d ** 2) / (2 * (70 * scale) ** 2)) * 0.10
            col = over(col, (0.65, 0.71, 0.99, inner))

            # V isareti
            vd = min(seg_dist(px, py, *a1, *a2), seg_dist(px, py, *a2, *a3))
            v = 1.0 - smooth(v_w - 1.2, v_w + 1.2, vd)
            if v > 0:
                vt = max(0.0, min(1.0, (py - a1[1]) / (a2[1] - a1[1])))
                col = over(col, (lerp(1.0, 0.65, vt), lerp(1.0, 0.84, vt), 1.0, v))
                # V cevresinde ince parlama
            vg = math.exp(-(vd ** 2) / (2 * (14 * scale) ** 2)) * 0.30
            col = over(col, (0.65, 0.84, 1.0, vg))

            i = (y * s + x) * 4
            pixels[i] = int(max(0, min(255, col[0] * 255)))
            pixels[i + 1] = int(max(0, min(255, col[1] * 255)))
            pixels[i + 2] = int(max(0, min(255, col[2] * 255)))
            pixels[i + 3] = int(max(0, min(255, col[3] * 255)))
    return bytes(pixels)


def solid(width, height, rgba):
    return bytes(bytearray(rgba) * (width * height))


def render_welcome(w, h):
    """Koyu gradyan zemin uzerinde iki yumusak renk kuresi."""
    pixels = bytearray(w * h * 4)
    for y in range(h):
        for x in range(w):
            fx, fy = x / w, y / h
            r = lerp(0.04, 0.02, fy)
            g = lerp(0.05, 0.03, fy)
            b = lerp(0.11, 0.07, fy)
            o1 = math.exp(-(((fx - 0.28) * 1.6) ** 2 + ((fy - 0.38) * 1.0) ** 2) / 0.05) * 0.55
            o2 = math.exp(-(((fx - 0.78) * 1.6) ** 2 + ((fy - 0.65) * 1.0) ** 2) / 0.06) * 0.45
            r = r + o1 * 0.39 + o2 * 0.02
            g = g + o1 * 0.40 + o2 * 0.71
            b = b + o1 * 0.95 + o2 * 0.83
            i = (y * w + x) * 4
            pixels[i] = int(min(255, r * 255))
            pixels[i + 1] = int(min(255, g * 255))
            pixels[i + 2] = int(min(255, b * 255))
            pixels[i + 3] = 255
    return bytes(pixels)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "build/assets"
    logo = render_logo(256)
    write_png(os.path.join(out, "plymouth", "logo.png"), 256, 256, logo)
    write_png(os.path.join(out, "plymouth", "bar_fill.png"), 4, 4, solid(4, 4, (56, 189, 248, 255)))
    write_png(os.path.join(out, "plymouth", "bar_bg.png"), 4, 4, solid(4, 4, (255, 255, 255, 36)))
    write_png(os.path.join(out, "calamares", "logo.png"), 256, 256, logo)
    write_png(os.path.join(out, "calamares", "welcome.png"), 640, 360, render_welcome(640, 360))
    print("Varliklar uretildi:", out)


if __name__ == "__main__":
    main()
