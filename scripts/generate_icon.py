#!/usr/bin/env bash
''':'
exec python3 "$0" "$@"
'''
import os
import sys
import subprocess
import math
from PIL import Image, ImageDraw, ImageFilter

def create_metronome_icon(size=1024):
    # Canvas with alpha channel
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # macOS Big Sur / Sonoma standard app icon squircle background
    # Icon squircle bounding box: standard 824x824 placed at (100, 100) on 1024x1024 canvas
    # Or rounded rect with radius ~185 on 824x824
    margin = 100
    w = size - 2 * margin
    h = size - 2 * margin
    r = int(w * 0.225) # standard macOS continuous corner ratio approx
    
    # Create background layer with soft drop shadow
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_box = [margin + 6, margin + 20, size - margin - 6, size - margin + 8]
    shadow_draw.rounded_rectangle(shadow_box, radius=r, fill=(0, 0, 0, 140))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=28))
    img.paste(shadow_layer, (0, 0), shadow_layer)

    # Base Squircle App Background - Deep Obsidian / Dark Brushed Metal Plate with subtle gradient
    base_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    base_draw = ImageDraw.Draw(base_layer)
    
    # Draw background gradient on squircle
    base_box = [margin, margin, size - margin, size - margin]
    
    # Mask for squircle
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(base_box, radius=r, fill=255)
    
    # Gradient surface: Rich Dark Studio Slate with subtle warm mahogany tone
    grad = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    grad_draw = ImageDraw.Draw(grad)
    for y in range(margin, size - margin):
        factor = (y - margin) / float(h)
        # Deep charcoal slate #1c1d22 to midnight black #0d0e12 with subtle purple/indigo undertone
        red = int(28 * (1 - factor) + 12 * factor)
        green = int(30 * (1 - factor) + 14 * factor)
        blue = int(40 * (1 - factor) + 20 * factor)
        grad_draw.line([(margin, y), (size - margin, y)], fill=(red, green, blue, 255))
        
    base_layer.paste(grad, (0, 0), mask)
    
    # Add subtle border highlight (macOS inner bevel)
    border_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border_layer)
    border_draw.rounded_rectangle(base_box, radius=r, outline=(255, 255, 255, 45), width=3)
    base_layer.paste(border_layer, (0, 0), border_layer)
    
    img.paste(base_layer, (0, 0), base_layer)
    
    # --- Metronome Body: Classic Pyramid / Trapezoid Shape ---
    # Center coordinates
    cx = size // 2
    
    # Trapezoid coordinates
    top_y = 220
    bottom_y = 780
    top_half_w = 110
    bottom_half_w = 260
    
    trap_pts = [
        (cx - top_half_w, top_y + 40),
        (cx - top_half_w + 30, top_y),
        (cx + top_half_w - 30, top_y),
        (cx + top_half_w, top_y + 40),
        (cx + bottom_half_w, bottom_y),
        (cx - bottom_half_w, bottom_y),
    ]
    
    # Metronome Body Shadow
    metro_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ms_draw = ImageDraw.Draw(metro_shadow)
    ms_draw.polygon(trap_pts, fill=(0, 0, 0, 180))
    metro_shadow = metro_shadow.filter(ImageFilter.GaussianBlur(radius=18))
    img.paste(metro_shadow, (0, 12), metro_shadow)
    
    # Metronome Outer Body (Polished Walnut / Rosewood & Brushed Metal Case)
    body_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    body_draw = ImageDraw.Draw(body_layer)
    
    # Create Body Mask
    body_mask = Image.new("L", (size, size), 0)
    bm_draw = ImageDraw.Draw(body_mask)
    bm_draw.polygon(trap_pts, fill=255)
    
    # Draw Body Texture (Rich dark walnut wood with warm amber glow)
    body_tex = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    bt_draw = ImageDraw.Draw(body_tex)
    for y in range(top_y, bottom_y + 1):
        factor = (y - top_y) / float(bottom_y - top_y)
        # Deep rich walnut: Top (65, 38, 28) -> Bottom (35, 20, 16)
        r_val = int(62 * (1 - factor) + 28 * factor)
        g_val = int(36 * (1 - factor) + 16 * factor)
        b_val = int(28 * (1 - factor) + 12 * factor)
        bt_draw.line([(0, y), (size, y)], fill=(r_val, g_val, b_val, 255))
        
    body_layer.paste(body_tex, (0, 0), body_mask)
    
    # Body gold/brass rim highlight
    body_rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    br_draw = ImageDraw.Draw(body_rim)
    br_draw.polygon(trap_pts, outline=(212, 175, 55, 90), width=4)
    body_layer.paste(body_rim, (0, 0), body_rim)
    
    img.paste(body_layer, (0, 0), body_layer)
    
    # --- Inner Soundboard / Metronome Scale Cutout ---
    inner_top_y = 280
    inner_bottom_y = 740
    inner_top_w = 70
    inner_bottom_w = 180
    
    inner_pts = [
        (cx - inner_top_w, inner_top_y),
        (cx + inner_top_w, inner_top_y),
        (cx + inner_bottom_w, inner_bottom_y),
        (cx - inner_bottom_w, inner_bottom_y),
    ]
    
    inner_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    in_draw = ImageDraw.Draw(inner_layer)
    
    in_mask = Image.new("L", (size, size), 0)
    inm_draw = ImageDraw.Draw(in_mask)
    inm_draw.polygon(inner_pts, fill=255)
    
    # Inner face gradient (Brushed gunmetal / matte black faceplate)
    inner_tex = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    it_draw = ImageDraw.Draw(inner_tex)
    for y in range(inner_top_y, inner_bottom_y + 1):
        factor = (y - inner_top_y) / float(inner_bottom_y - inner_top_y)
        # Gunmetal scale plate: (22, 24, 28) -> (14, 15, 18)
        gray = int(26 * (1 - factor) + 12 * factor)
        it_draw.line([(0, y), (size, y)], fill=(gray, gray + 2, gray + 6, 255))
        
    inner_layer.paste(inner_tex, (0, 0), in_mask)
    
    # Inner bevel shadow (inset shadow)
    inner_bevel = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ib_draw = ImageDraw.Draw(inner_bevel)
    ib_draw.polygon(inner_pts, outline=(0, 0, 0, 220), width=4)
    inner_layer.paste(inner_bevel, (0, 0), inner_bevel)
    
    # Tempo Scale Hash Marks (Engraved gold / ivory ticks)
    for idx, y_tick in enumerate(range(inner_top_y + 50, inner_bottom_y - 60, 32)):
        tick_ratio = (y_tick - inner_top_y) / float(inner_bottom_y - inner_top_y)
        cur_w = inner_top_w + (inner_bottom_w - inner_top_w) * tick_ratio
        
        # Draw horizontal hash marks on left and right sides
        tick_len = 22 if idx % 2 == 0 else 14
        opacity = 180 if idx % 2 == 0 else 110
        
        # Left ticks
        lx1 = int(cx - cur_w + 14)
        lx2 = int(lx1 + tick_len)
        it_draw.line([(lx1, y_tick), (lx2, y_tick)], fill=(220, 200, 160, opacity), width=3 if idx % 2 == 0 else 2)
        
        # Right ticks
        rx1 = int(cx + cur_w - 14)
        rx2 = int(rx1 - tick_len)
        it_draw.line([(rx1, y_tick), (rx2, y_tick)], fill=(220, 200, 160, opacity), width=3 if idx % 2 == 0 else 2)
        
    inner_layer.paste(inner_tex, (0, 0), in_mask)
    img.paste(inner_layer, (0, 0), inner_layer)
    
    # --- Metronome Pendulum Arm & Sliding Weight (Stylized Dynamic Angle) ---
    # Pivot at bottom center (cx, 740)
    pivot_x = cx
    pivot_y = 730
    
    # Pendulum angled slightly to the right (~14 degrees) for dynamic rhythm feel
    angle_rad = math.radians(14)
    arm_length = 460
    
    top_arm_x = pivot_x + arm_length * math.sin(angle_rad)
    top_arm_y = pivot_y - arm_length * math.cos(angle_rad)
    
    # Pendulum rod shadow
    pend_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ps_draw = ImageDraw.Draw(pend_shadow)
    ps_draw.line([(pivot_x + 8, pivot_y + 6), (top_arm_x + 8, top_arm_y + 6)], fill=(0, 0, 0, 160), width=10)
    pend_shadow = pend_shadow.filter(ImageFilter.GaussianBlur(radius=8))
    img.paste(pend_shadow, (0, 0), pend_shadow)
    
    # Pendulum Chrome/Silver Rod
    rod_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rod_draw = ImageDraw.Draw(rod_layer)
    rod_draw.line([(pivot_x, pivot_y), (top_arm_x, top_arm_y)], fill=(230, 235, 245, 255), width=8)
    rod_draw.line([(pivot_x - 1, pivot_y), (top_arm_x - 1, top_arm_y)], fill=(255, 255, 255, 220), width=3) # Rod highlight
    img.paste(rod_layer, (0, 0), rod_layer)
    
    # Sliding Brass / Gold Weight on Pendulum
    weight_pos = 0.52 # Position along pendulum rod
    wx = pivot_x + (arm_length * weight_pos) * math.sin(angle_rad)
    wy = pivot_y - (arm_length * weight_pos) * math.cos(angle_rad)
    
    weight_w = 46
    weight_h = 56
    
    # Draw Sliding Weight with metallic gold sheen
    weight_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(weight_layer)
    
    # Rotated bounding box for weight
    w_rect = [
        (wx - weight_w/2, wy - weight_h/2),
        (wx + weight_w/2, wy - weight_h/2),
        (wx + weight_w/2 + 6, wy + weight_h/2),
        (wx - weight_w/2 - 6, wy + weight_h/2),
    ]
    # Simple polygon for weight
    cos_a = math.cos(angle_rad)
    sin_a = math.sin(angle_rad)
    
    def rotate_pt(px, py, ox, oy):
        dx = px - ox
        dy = py - oy
        return (ox + dx * cos_a - dy * sin_a, oy + dx * sin_a + dy * cos_a)
        
    rot_w_pts = [
        rotate_pt(wx - weight_w/2, wy - weight_h/2, wx, wy),
        rotate_pt(wx + weight_w/2, wy - weight_h/2, wx, wy),
        rotate_pt(wx + weight_w/2 + 4, wy + weight_h/2, wx, wy),
        rotate_pt(wx - weight_w/2 - 4, wy + weight_h/2, wx, wy),
    ]
    
    # Weight shadow
    w_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ws_draw = ImageDraw.Draw(w_shadow)
    ws_draw.polygon([(p[0] + 6, p[1] + 8) for p in rot_w_pts], fill=(0, 0, 0, 160))
    w_shadow = w_shadow.filter(ImageFilter.GaussianBlur(radius=6))
    img.paste(w_shadow, (0, 0), w_shadow)
    
    # Weight Body: Polished Brass / 24k Gold
    w_draw.polygon(rot_w_pts, fill=(245, 195, 68, 255), outline=(255, 235, 140, 255))
    # Weight center groove
    groove_p1 = rotate_pt(wx - weight_w/2 + 6, wy, wx, wy)
    groove_p2 = rotate_pt(wx + weight_w/2 - 6, wy, wx, wy)
    w_draw.line([groove_p1, groove_p2], fill=(160, 110, 25, 240), width=4)
    img.paste(weight_layer, (0, 0), weight_layer)
    
    # Pivot Bottom Screw / Cap
    pivot_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pv_draw = ImageDraw.Draw(pivot_layer)
    pv_draw.ellipse([pivot_x - 18, pivot_y - 18, pivot_x + 18, pivot_y + 18], fill=(210, 170, 50, 255), outline=(255, 230, 120, 255), width=3)
    pv_draw.ellipse([pivot_x - 8, pivot_y - 8, pivot_x + 8, pivot_y + 8], fill=(60, 45, 20, 255))
    img.paste(pivot_layer, (0, 0), pivot_layer)
    
    # --- Neon Beat Indicator LED Array at the Bottom Plate ---
    # 4 LED Beat dots: 1 Active Glowing Neon Emerald / Cyan Beat (Downbeat) + 3 Sub-beat LEDs
    led_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    led_draw = ImageDraw.Draw(led_layer)
    
    led_y = 675
    dot_spacing = 42
    led_count = 4
    start_led_x = cx - int((led_count - 1) * dot_spacing / 2)
    
    for i in range(led_count):
        lx = start_led_x + i * dot_spacing
        if i == 0:
            # Active downbeat glow (Vibrant Neon Mint / Electric Cyan #00FFCC)
            glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            g_draw = ImageDraw.Draw(glow_layer)
            g_draw.ellipse([lx - 24, led_y - 24, lx + 24, led_y + 24], fill=(0, 255, 200, 160))
            glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=12))
            img.paste(glow_layer, (0, 0), glow_layer)
            
            # Core neon bulb
            led_draw.ellipse([lx - 10, led_y - 10, lx + 10, led_y + 10], fill=(210, 255, 245, 255), outline=(0, 255, 200, 255), width=3)
        elif i == 1:
            # Active swing beat (Vibrant Electric Orange/Amber #FF9500)
            glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            g_draw = ImageDraw.Draw(glow_layer)
            g_draw.ellipse([lx - 18, led_y - 18, lx + 18, led_y + 18], fill=(255, 150, 0, 120))
            glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=8))
            img.paste(glow_layer, (0, 0), glow_layer)
            
            led_draw.ellipse([lx - 8, led_y - 8, lx + 8, led_y + 8], fill=(255, 220, 150, 255), outline=(255, 150, 0, 255), width=2)
        else:
            # Inactive beat indicator (Dim recessed LED)
            led_draw.ellipse([lx - 7, led_y - 7, lx + 7, led_y + 7], fill=(35, 40, 48, 220), outline=(60, 68, 80, 200), width=2)
            
    img.paste(led_layer, (0, 0), led_layer)
    
    # --- Subtle Gloss / Glass Lens Sheen across top half of icon ---
    gloss_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gloss_draw = ImageDraw.Draw(gloss_layer)
    
    # Curved highlight diagonal
    gloss_draw.polygon([
        (margin, margin),
        (size - margin, margin),
        (size - margin, margin + 280),
        (margin, margin + 180),
    ], fill=(255, 255, 255, 18))
    
    gloss_layer = gloss_layer.filter(ImageFilter.GaussianBlur(radius=10))
    # Mask gloss to squircle
    img.paste(gloss_layer, (0, 0), mask)
    
    return img

def generate_iconset(master_png_path, iconset_dir):
    os.makedirs(iconset_dir, exist_ok=True)
    
    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    
    for filename, px in sizes:
        out_path = os.path.join(iconset_dir, filename)
        # Use sips or Pillow for high quality resampling
        cmd = ["sips", "-z", str(px), str(px), master_png_path, "--out", out_path]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"Generated icon: {filename} ({px}x{px})")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))
    build_dir = os.path.join(root_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    
    master_png = os.path.join(build_dir, "AppIcon_1024.png")
    iconset_dir = os.path.join(build_dir, "AppIcon.iconset")
    icns_path = os.path.join(build_dir, "AppIcon.icns")
    
    print("[1/3] Generating 1024x1024 master icon image with Pillow...")
    img = create_metronome_icon(1024)
    img.save(master_png, "PNG")
    print(f"Master icon saved to {master_png}")
    
    print("[2/3] Generating macOS AppIcon.iconset multi-resolution hierarchy...")
    generate_iconset(master_png, iconset_dir)
    
    print("[3/3] Compiling AppIcon.icns with iconutil...")
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
    print(f"Successfully compiled native icon: {icns_path}")

if __name__ == "__main__":
    main()
