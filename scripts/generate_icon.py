#!/usr/bin/env bash
''':'
exec python3 "$0" "$@"
'''
import os
import sys
import subprocess
from PIL import Image, ImageDraw, ImageFilter

def process_image_to_icon(input_image_path, size=1024):
    """
    Processes the user image into a pixel-perfect macOS standard application icon:
    - 1024x1024 canvas with transparent background
    - Standard macOS squircle dimensions (824x824 bounding box with margin=100)
    - Apple standard continuous squircle curvature (r = 185px)
    - Ambient drop shadow underneath the squircle plate
    - Precision inner bevel / border stroke for crisp rendering across light & dark macOS docks
    """
    if not os.path.exists(input_image_path):
        raise FileNotFoundError(f"Input image not found: {input_image_path}")

    orig = Image.open(input_image_path).convert("RGBA")
    
    # macOS Big Sur / Sonoma standard app icon canvas parameters
    margin = 100
    squircle_size = size - 2 * margin  # 824 for 1024x1024
    r = int(squircle_size * 0.225)      # ~185 for 824x824

    # Fit / Crop source image to square if needed, then high-quality Lanczos resample to squircle_size
    orig_w, orig_h = orig.size
    min_dim = min(orig_w, orig_h)
    crop_x = (orig_w - min_dim) // 2
    crop_y = (orig_h - min_dim) // 2
    square_art = orig.crop((crop_x, crop_y, crop_x + min_dim, crop_y + min_dim))
    art_resized = square_art.resize((squircle_size, squircle_size), Image.Resampling.LANCZOS)

    # Master canvas with transparent alpha
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # 1. Soft ambient drop shadow underneath squircle plate
    shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_layer)
    shadow_box = [margin + 4, margin + 18, size - margin - 4, size - margin + 12]
    s_draw.rounded_rectangle(shadow_box, radius=r, fill=(0, 0, 0, 115))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=26))
    canvas.paste(shadow_layer, (0, 0), shadow_layer)

    # 2. Squircle mask
    squircle_mask = Image.new("L", (squircle_size, squircle_size), 0)
    m_draw = ImageDraw.Draw(squircle_mask)
    m_draw.rounded_rectangle([0, 0, squircle_size, squircle_size], radius=r, fill=255)

    # 3. Squircle artwork plate
    squircle_plate = Image.new("RGBA", (squircle_size, squircle_size), (0, 0, 0, 0))
    squircle_plate.paste(art_resized, (0, 0), squircle_mask)

    # 4. Clean squircle border highlight & inner bevel
    border_layer = Image.new("RGBA", (squircle_size, squircle_size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(border_layer)
    # Subtle outer stroke for contrast on pure white backgrounds
    b_draw.rounded_rectangle([0, 0, squircle_size - 1, squircle_size - 1], radius=r, outline=(0, 0, 0, 45), width=2)
    # Subtle inner bevel highlight
    b_draw.rounded_rectangle([1, 1, squircle_size - 2, squircle_size - 2], radius=r - 1, outline=(255, 255, 255, 70), width=2)
    
    squircle_plate = Image.alpha_composite(squircle_plate, border_layer)

    # Composite squircle plate onto canvas
    canvas.paste(squircle_plate, (margin, margin), squircle_mask)

    return canvas

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
    
    master_img = Image.open(master_png_path).convert("RGBA")
    for filename, px in sizes:
        out_path = os.path.join(iconset_dir, filename)
        # Generate with high-quality Pillow Lanczos resampling for pixel-perfect clarity
        resized = master_img.resize((px, px), Image.Resampling.LANCZOS)
        resized.save(out_path, "PNG")
        print(f"Generated icon: {filename} ({px}x{px})")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))
    build_dir = os.path.join(root_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    
    # Candidate source image paths
    candidates = [
        os.path.join(root_dir, "Gemini_Generated_Image_llg4pollg4pollg4.jpeg"),
        os.path.join(root_dir, "Gemini_Generated_Image_llg4pollg4pollg4.jpg"),
        os.path.join(root_dir, "Gemini_Generated_Image_llg4pollg4pollg4.png"),
    ]
    
    input_image = None
    for cand in candidates:
        if os.path.exists(cand):
            input_image = cand
            break
            
    if not input_image:
        print(f"Error: Source image Gemini_Generated_Image_llg4pollg4pollg4.jpeg not found in {root_dir}", file=sys.stderr)
        sys.exit(1)
        
    master_png = os.path.join(build_dir, "AppIcon_1024.png")
    iconset_dir = os.path.join(build_dir, "AppIcon.iconset")
    icns_path = os.path.join(build_dir, "AppIcon.icns")
    
    print(f"[1/3] Processing master icon from {os.path.basename(input_image)}...")
    img = process_image_to_icon(input_image, 1024)
    img.save(master_png, "PNG")
    print(f"Master icon saved to {master_png}")
    
    print("[2/3] Generating macOS AppIcon.iconset multi-resolution hierarchy...")
    generate_iconset(master_png, iconset_dir)
    
    print("[3/3] Compiling AppIcon.icns with iconutil...")
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
    print(f"Successfully compiled native icon: {icns_path}")

if __name__ == "__main__":
    main()
