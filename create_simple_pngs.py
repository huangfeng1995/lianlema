#!/usr/bin/env python3
"""Create simple RGB PNG files using only built-in libraries (struct + zlib)."""
import struct
import zlib
import os

def create_png(width, height, rgb_pixels, output_path):
    """
    Create a PNG file from raw RGB pixel data (no alpha).
    rgb_pixels: list of (r, g, b) tuples, row by row
    """
    def png_chunk(chunk_type, data):
        chunk_len = struct.pack('>I', len(data))
        chunk_crc = struct.pack('>I', zlib.crc32(chunk_type + data) & 0xffffffff)
        return chunk_len + chunk_type + data + chunk_crc

    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'

    # IHDR: width, height, bit_depth=8, color_type=2 (RGB), compression=0, filter=0, interlace=0
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)

    # Build raw image data with filter bytes
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter type: none
        for x in range(width):
            r, g, b = rgb_pixels[y * width + x]
            raw_data += bytes([r, g, b])

    # Compress with zlib
    compressed = zlib.compress(raw_data, 9)
    idat = png_chunk(b'IDAT', compressed)

    # IEND
    iend = png_chunk(b'IEND', b'')

    with open(output_path, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

    print(f"Created: {output_path}")

def make_color_icon(size, r, g, b):
    """Create a solid color square icon."""
    pixels = [(r, g, b) for _ in range(size * size)]
    return pixels

def make_circle_icon(size, bg_r, bg_g, bg_b, fg_r, fg_g, fg_b):
    """Create a circular icon: colored circle on colored background."""
    cx = size // 2
    cy = size // 2
    radius = size // 2 - 1
    pixels = []
    for y in range(size):
        for x in range(size):
            dist_sq = (x - cx) ** 2 + (y - cy) ** 2
            if dist_sq <= radius ** 2:
                pixels.append((fg_r, fg_g, fg_b))  # foreground color
            else:
                pixels.append((bg_r, bg_g, bg_b))  # background
    return pixels

# For the badge directory - these are for streak achievements
badge_dir = os.path.join(os.path.dirname(__file__), 'assets/images/badge')
icon_dir = os.path.join(os.path.dirname(__file__), 'assets/images/icon')

SIZE = 24

# --- Badge icons (for achievement badges like badge_01_hatch etc.) ---
# badge_01_hatch - red/orange fire
pixels = make_circle_icon(SIZE, 255, 200, 100, 255, 80, 0)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_01_hatch.png'))

# badge_02_fire7 - orange fire  
pixels = make_circle_icon(SIZE, 255, 220, 150, 255, 100, 0)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_02_fire7.png'))

# badge_03_lightning - yellow lightning bolt
pixels = make_circle_icon(SIZE, 255, 255, 180, 255, 220, 0)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_03_lightning.png'))

# badge_04_gem - blue gem
pixels = make_circle_icon(SIZE, 200, 220, 255, 50, 100, 255)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_04_gem.png'))

# badge_05_crown - gold crown
pixels = make_circle_icon(SIZE, 255, 240, 180, 255, 200, 0)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_05_crown.png'))

# badge_06_target - red target
pixels = make_circle_icon(SIZE, 255, 200, 200, 255, 50, 50)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_06_target.png'))

# badge_07_trophy - gold trophy
pixels = make_circle_icon(SIZE, 255, 245, 180, 255, 200, 0)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_07_trophy.png'))

# badge_08_skull - gray skull
pixels = make_circle_icon(SIZE, 200, 200, 200, 100, 100, 100)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_08_skull.png'))

# badge_09_calendar - blue calendar
pixels = make_circle_icon(SIZE, 200, 220, 255, 60, 130, 255)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_09_calendar.png'))

# badge_10_sprout - green sprout
pixels = make_circle_icon(SIZE, 200, 255, 200, 50, 200, 50)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_10_sprout.png'))

# badge_medal - gold medal
pixels = make_circle_icon(SIZE, 255, 230, 150, 255, 180, 0)
create_png(SIZE, SIZE, pixels, os.path.join(badge_dir, 'badge_medal.png'))

# --- Icon directory ---
# streak_fire - red/orange fire icon
pixels = make_circle_icon(SIZE, 255, 180, 80, 255, 50, 0)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'streak_fire.png'))

# check_fire - green check fire
pixels = make_circle_icon(SIZE, 180, 255, 180, 0, 200, 0)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'check_fire.png'))

# calendar_icon - blue calendar
pixels = make_circle_icon(SIZE, 200, 220, 255, 60, 130, 255)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'calendar_icon.png'))

# settings_gear - gray gear
pixels = make_circle_icon(SIZE, 180, 180, 180, 120, 120, 120)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'settings_gear.png'))

# export_icon - green export
pixels = make_circle_icon(SIZE, 180, 255, 200, 0, 180, 80)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'export_icon.png'))

# target_icon - red target
pixels = make_circle_icon(SIZE, 255, 200, 200, 255, 50, 50)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'target_icon.png'))

# shield_icon - blue shield
pixels = make_circle_icon(SIZE, 180, 210, 255, 40, 100, 255)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'shield_icon.png'))

# sprint_icon - orange sprint
pixels = make_circle_icon(SIZE, 255, 220, 180, 255, 120, 0)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'sprint_icon.png'))

# warning_icon - yellow warning
pixels = make_circle_icon(SIZE, 255, 255, 180, 255, 200, 0)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'warning_icon.png'))

# monthly_boss_icon - red boss
pixels = make_circle_icon(SIZE, 255, 180, 180, 200, 0, 0)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'monthly_boss_icon.png'))

# boss_monster - purple boss monster
pixels = make_circle_icon(SIZE, 220, 180, 255, 150, 0, 200)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'boss_monster.png'))

# app_icon - blue app icon
pixels = make_circle_icon(SIZE, 180, 210, 255, 30, 100, 255)
create_png(SIZE, SIZE, pixels, os.path.join(icon_dir, 'app_icon.png'))

print("\nAll PNG files created successfully!")
print("Verifying with zlib decompress...")

import struct
for f in [
    os.path.join(icon_dir, 'streak_fire.png'),
    os.path.join(badge_dir, 'badge_01_hatch.png'),
]:
    with open(f, 'rb') as fh:
        data = fh.read()
    pos = 8
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        chunk_type = data[pos+4:pos+8].decode()
        chunk_data = data[pos+8:pos+8+length]
        if chunk_type == 'IHDR':
            w, h, bitd, colt, comp, filt, inter = struct.unpack('>IIBBBBB', chunk_data)
            print("  {}: {}x{} bitd={} colt={}".format(os.path.basename(f), w, h, bitd, colt))
        if chunk_type == 'IDAT':
            decompressed = zlib.decompress(chunk_data)
            expected = w * h * 3 + h  # RGB + filter bytes
            print("  IDAT: decompressed {} bytes (expected ~{})".format(len(decompressed), expected))
        pos += 12 + length
        if chunk_type == 'IEND':
            break
